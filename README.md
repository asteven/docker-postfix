# docker-postfix

Postfix running in the foreground inside a docker container.


## Configuration

The configuration is done in away that allows you to apply your existing
postfix know-how instead of having to deal with some abstraction or newly
invented variable names.

You have to understand postfix to make use of all this.

Therefore refer to the postfix documentation for possible configuration settings:

- http://www.postfix.org/postconf.5.html
- http://www.postfix.org/wip.html#master
- http://www.postfix.org/DATABASE_README.html



### Configuration via files/folders

The container considers config files and variables in /config:

- /config/master with changes for settings usually configured in master.cf.
- /config/main with changes for settings usually configured in main.cf.
- /config/tables/ containing files for use with `postmap`

Each line in /config/master that starts with '-' is passed to `postconf`
verbatim. All other lines are passed to `postconf -M`.

Each line in /config/main is passed to `postconf` verbatim.

Each file in /config/tables/ becomes a postmap file at /etc/postfix/{filename}



### Configuration via environment variables

Environment variables override configuration from /config/.

Environment variables are interpreted as follows:

```
POSTCONF_{name}={value} -> postconf {name}={value}

POSTCONF_{param}_{name}={value} -> postconf -{param} {name}={value}
```

where param is one of the postconf supported params: X|M|F|P|MX|PX

Note: / (slash) in variable names has to be escaped with __ (double underscore).

e.g.:
```
  export POSTCONF_mydestination='$myhostname, localhost.$mydomain, localhost'
  -> postconf 'mydestination=$myhostname, localhost.$mydomain, localhost'
  export POSTCONF_X_mydestination=
  -> postconf -X mydestination
  export POSTCONF_M_submission__inet="submission inet n - y - - smtpd"
  -> postconf -M submission/inet="submission inet n - y - - smtpd"
  export POSTCONF_F_submission__inet__chroot=n
  -> postconf -F submission/inet/chroot=n
  export POSTCONF_P_submission__inet__smtpd_upstream_proxy_protocol=haproxy
  -> postconf -P submission/inet/smtpd_upstream_proxy_protocol=haproxy
  export export POSTCONF_MX_submission__inet=
  -> postconf -MX submission/inet
```

Additionally any environment variable prefixed with POSTMAP_ defines a postfix
lookup table in /etc/postfix.

```
POSTMAP_{filename}={value} -> /etc/postfix/{filename} containing {value}
```

e.g.:
```
  POSTMAP_smtpd_recipient_restrictions="blackhole.example.com DISCARD"
  -> echo "blackhole.example.com DISCARD" > /etc/postfix/smtpd_recipient_restrictions
     postmap /etc/postfix/smtpd_recipient_restrictions
```

