FROM johanadriaans/docker-base-alpine:3.4
MAINTAINER Johan Adriaans <johan@driaans.nl>

# Check latest stable version here: https://suhosin.org/stories/download.html
ENV SUHOSIN_VERSION 0.9.38

# Update base image
# Add sources for latest nginx
# Install software requirementsa
RUN apk --update add --virtual .build-dependencies php5-dev autoconf gcc make sed musl-dev re2c file openssl \
  && cd /tmp \
  && wget https://download.suhosin.org/suhosin-$SUHOSIN_VERSION.tar.gz \
  && tar -zxvf suhosin-$SUHOSIN_VERSION.tar.gz \
  && cd /tmp/suhosin-$SUHOSIN_VERSION \
  # Alpine linux has flock() stuff in file.h
  && sed -i '1i#include <sys/file.h>' log.c \
  && phpize \
  && ./configure \
  && make \
  && NO_INTERACTION=1 make test \
  && make install \
  && rm -rf /tmp/suhosin-$SUHOSIN_VERSION \
  && apk del .build-dependencies \

  && apk --update add mariadb-client ssmtp nginx ca-certificates libxml2 php5-fpm php5-json php5-zlib php5-xml php5-curl php5-ctype php5-dom php5-mysqli php5-gd php5-iconv php5-opcache \
  && adduser www-data -S -H -h /var/www -s /sbin/nologin \
  && mkdir -p /etc/service/nginx \
  && mkdir -p /etc/nginx/error_pages \
  && ln -s /usr/sbin/nginx /etc/service/nginx/run \
  && chown -R www-data:www-data /var/lib/nginx \
  && rm -rf /var/www/localhost \
  && rm -rf /var/www/vhosts \
  && wget http://browscap.org/stream?q=Lite_PHP_BrowsCapINI -O /etc/php5/browscap.ini

# nginx and php-fpm site conf
RUN rm -Rf /etc/nginx/conf.d/*
ADD files/nginx.conf /etc/nginx/nginx.conf
ADD files/dynamic-vhosts.conf /etc/nginx/conf.d/dynamic-vhosts.conf
ADD files/vhost-defaults.conf /etc/nginx/vhost-defaults.conf
ADD files/php-fpm.conf /etc/php5/php-fpm.conf
ADD files/www.conf-light /etc/php/fpm/pool.d/www.conf
ADD files/php.ini /etc/php5/fpm/php.ini
ADD files/service /etc/service

# Debug
#RUN apk --update add --virtual .build-dependencies git php-dev autoconf gcc make sed musl-dev re2c file openssl \
#  && cd /tmp \
#  && git clone git://github.com/xdebug/xdebug.git \
#  && cd xdebug \
#  && phpize \
#  && ./configure --enable-xdebug \
#  && make install \
#  && rm -rf /tmp/xdebug \
#  && apk del .build-dependencies \
#  && echo "zend_extension=xdebug.so" >> /etc/php/fpm/php.ini \
#  && echo "xdebug.profiler_enable_trigger=1" >> /etc/php/fpm/php.ini \
#  && echo "xdebug.profiler_output_dir=/var/www/data/webgrind/httpdocs/xdebug_output" >> /etc/php/fpm/php.ini

EXPOSE 8080

ENTRYPOINT ["/sbin/dumb-init", "/sbin/runsvdir", "-P", "/etc/service"]
