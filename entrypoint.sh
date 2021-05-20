#!/bin/sh

#set -x

# Apply configuration to /etc/postfix/master.cfg.
if [ -f /config/master ]; then
   while read -r line; do
      [ -z "$line" ] && continue
      [ "${line:0:1}" = "#" ] && continue
      [ "${line:0:4}" = "#EOF" ] && break
      # nuke leading and trailing whitespace
      config="$(echo $line)"
      case "$config" in
         "-*")
            # Support any of the master.cf related options like -M, -F, -P
            echo "postconf $config"
            postconf $config
         ;;
         *)
            # Default to -M
            echo "postconf -M $config"
            postconf -M "$config"
         ;;
      esac
   done < /config/master
fi

# Apply configuration to /etc/postfix/main.cfg.
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

# Environment variables override configuration from /config/main.
# POSTFIX_{name}={value} -> postconf {name}={value}
env | grep ^POSTFIX_ | sed 's/^POSTFIX_//' \
| while read -r config; do
   echo "postconf $config"
   postconf "$config"
done


# Log to stdout.
postconf "maillog_file=/dev/stdout"

# Unclean container stop might leave pid files around.
rm -f /var/spool/postfix/pid/master.pid

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
