# docker-postfix

Postfix running in the foreground inside a docker container.

Configured via files mounted at:

/config/master with changes for settings usually configured in master.cf.
/config/main with changes for settings usually configured in main.cf.

Each line in /config/master that starts with '-' is passed to `postconf`
verbatim. All other lines are passed to `postconf -M`.

Eeach line in /config/main is passed to `postconf` verbatim.

Additionally any environment variable prefixed with POSTFIX_ is passed to `postconf`.

POSTFIX_{name}={value} -> postconf {name}={value}

e.g. POSTFIX_myhostname=some.cool.name -> `postconf myhostname=some.cool.name`

Settings from environment variables take precedence over those in config files.

