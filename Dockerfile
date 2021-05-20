FROM docker.io/alpine:3

LABEL maintainer "Steven Armstrong <steven.armstrong@id.ethz.ch>"

RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
    && echo '@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

RUN apk --no-cache add --upgrade apk-tools@edge; \
    apk --no-cache update; \
    apk --no-cache add tini \
    postfix openssl

# Tini is now available at /sbin/tini
ENTRYPOINT ["/sbin/tini", "--"]

EXPOSE 25

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

CMD ["/entrypoint.sh"]
