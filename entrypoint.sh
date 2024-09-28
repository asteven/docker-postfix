#!/bin/sh

if [ "${DEBUG-}" ]; then
   set -x
fi


# Apply configuration to /etc/postfix/master.cf.
if [ -f /config/master ]; then
   while read -r line; do
      [ -z "$line" ] && continue
      [ "${line:0:1}" = "#" ] && continue
      [ "${line:0:4}" = "#EOF" ] && break
      # nuke leading and trailing whitespace
      config="$(echo $line)"
      case "$config" in
         "-*")
            # Support any of the master.cf related options like -M, -F, -P, -MX, -PX
            option="${config%% *}"
            echo "postconf $option \"$config\""
            postconf $option "$config"
         ;;
         *)
            # Default to -M
            echo "postconf -M $config"
            postconf -M "$config"
         ;;
      esac
   done < /config/master
fi


# Apply configuration to /etc/postfix/main.cf.
if [ -f /config/main ]; then
   while read -r line; do
      [ -z "$line" ] && continue
      [ "${line:0:1}" = "#" ] && continue
      [ "${line:0:4}" = "#EOF" ] && break
      # nuke leading and trailing whitespace
      config="$(echo $line)"
      echo "postconf $config"
      postconf "$config"
   done < /config/main
fi


# Environment variables override configuration from /config/master and /config/main.
# See ./README.md for more information how this works.
env | grep ^POSTCONF_ | sed 's|^POSTCONF_||' \
| while read -r config; do
   param=
   case "$config" in
      X_*|M_*|F_*|P_*|MX_*|PX_*)
         param="${config%%_*}"
         config="${config#*_}"
      ;;
   esac
   # replace __ with /
   key="$(echo "${config%=*}" | sed 's|__|/|g')"
   value="${config#*=}"
   [ -n "$value" ] && entry="$key=$value" || entry="$key"
   [ -n "$param" ] && {
      echo "postconf -${param} $entry"
      postconf -${param} "$entry"
   } || {
      echo "postconf $entry"
      postconf "$entry"
   }
done


# Create postmap tables in /etc/postfix/{name}
if [ -d /config/tables ]; then
   for name in $(ls -1 /config/tables); do
      file="/etc/postfix/$name"
      cp "/config/tables/$name" "$file"
      var_name="$(grep -v '^#' /etc/postfix/main.cf | awk -F= -v file="$file" '{if ($2 ~ file) print $1}')"
      map="$(postconf -h $var_name)"
      echo "postmap $map"
      postmap "$map" || true
   done
fi


# Environment variables override configuration from /config/tables
# See ./README.md for more information how this works.
env | grep ^POSTMAP_ | sed 's/^POSTMAP_//' \
| while read -r config; do
   key="${config%=*}"
   file="/etc/postfix/$key"
   name='$'"POSTMAP_$key"
   eval value=$name
   echo "$value" > "$file"
   var_name="$(grep -v '^#' /etc/postfix/main.cf | awk -F= -v file="$file" '{if ($2 ~ file) print $1}')"
   map="$(postconf -h $var_name)"
   echo "postmap $map"
   postmap "$map" || true
done


# Log to stdout.
postconf "maillog_file=/dev/stdout"

# Ensure there's now stray pid file.
rm -f /var/spool/postfix/pid/master.pid

# TODO: do this in dockerfile instead so the container can potentially run rootless.
# Ensure we can write our stuff.
chown postfix:root /var/lib/postfix
chown -R postfix: /var/lib/postfix/*
chown root:root /var/spool/postfix

postalias /etc/postfix/aliases

[ -d /var/spool/postfix/etc ] && {
   cp /etc/hosts /var/spool/postfix/etc/hosts
}

postfix check
postfix set-permissions

# Run in foreground.
exec postfix start-fg
