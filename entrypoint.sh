#!/bin/sh

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
