# docker-postfix

Postfix running in the foreground inside a docker container.

Configured via environment variables.

Any environment variable prefixed with POSTFIX_ is passed to `postconf`.

POSTFIX_{name}={value} -> postconf {name}={value}

e.g. POSTFIX_myhostname=some.cool.name -> `postconf myhostname=some.cool.name`


