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
            # Support any of the master.cf related options like -M, -F, -P, -MX, -PX
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

# Environment variables override configuration from /config/master and /config/main.
# POSTFIX_{name}={value} -> postconf {name}={value}
env | grep ^POSTFIX_ | sed 's/^POSTFIX_//' \
| while read -r config; do
   echo "postconf $config"
   postconf "$config"
done

# Environment variables override configuration from /config/master and /config/main.
#
# POSTCONF_{param}_{name}={value} -> postconf -{param} {name}={value}
# where param is one of the postfix master.cf supported service fields: M|F|P|MX|PX
# / (slash) has to be escaped with __ (double underscore).
#
# e.g.:
#   export POSTCONF_M_submission__inet="submission inet n - y - - smtpd"
#   -> postconf -M submission/inet="submission inet n - y - - smtpd"
#   export POSTCONF_F_submission__inet__chroot=n
#   -> postconf -F submission/inet/chroot=n
#   export POSTCONF_P_submission__inet__smtpd_upstream_proxy_protocol=haproxy
#   -> postconf -P submission/inet/smtpd_upstream_proxy_protocol=haproxy
#   export export POSTCONF_MX_submission__inet=
#   -> postconf -MX submission/inet
env | grep ^POSTCONF_ | sed 's|^POSTCONF_||' \
| while read -r config; do
   case "$config" in
      M_*|F_*|P_*|MX_*|PX_*)
         param="${config%%_*}"
         config="${config#*_}"
      ;;
   esac
   # replace __ with /
   key="$(echo "${config%=*}" | sed 's|__|/|g')"
   value="${config#*=}"
   [ -n "$value" ] && entry="$key=$value" || entry="$key"
   echo "postconf -${param} $entry"
   postconf -${param} "$entry"
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
