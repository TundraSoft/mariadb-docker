FROM tundrasoft/alpine-base
LABEL maintainer="Abhinav A V<abhai2k@gmail.com>"

ENV MARIADB_ROOT_PASSWORD= \
  MARIADB_DATABASE= \
  MARIADB_USER= \
  MARIADB_PASSWORD= \
  MARIADB_CHARSET="utf8" \
  MARIADB_COLLATION="utf8_general_ci"

# ARG RSYSLOG_VERSION=8.1904.0-r1

# RUN apk add --update gzip logrotate rsyslog=$RSYSLOG_VERSION \
#   rsyslog-mysql=$RSYSLOG_VERSION tar xz && \
#   rm -fr /var/log/* /var/cache/apk/*

RUN apk add --update pwgen \
  mariadb \
  mariadb-client \
  && rm -fr /var/log/* \
  /var/cache/apk/*

ADD /rootfs/ /

RUN mkdir -p /data/db/mysql \
  /data/log/mysql \
  /data/conf \
  /var/run/mysqld

VOLUME /data /init.d

EXPOSE 3306

