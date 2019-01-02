FROM yiisoftware/yii2-php:7.2-apache
# System - Update embded package
RUN apt-get -y update \
    && apt-get -y upgrade
# System - Set default timezone
ENV TZ Europe/Paris
RUN chgrp 0 /etc/timezone /etc \
    && chmod g=u /etc/timezone /etc
# Apache - Fix upstream link error
RUN ([ -d /var/www/html ] && rm -rf /var/www/html && ln -s /app/web/ /var/www/html) || true
# Apache - enable rewrite
RUN a2enmod rewrite
# Apache - remoteip module
RUN a2enmod remoteip
RUN sed -i 's/%h/%a/g' /etc/apache2/apache2.conf
ENV REMOTE_IP_HEADER X-Forwarded-For
ENV REMOTE_IP_TRUSTED_PROXY 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
ENV REMOTE_IP_INTERNAL_PROXY 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
# Apache - Disable useless configuration
RUN a2disconf serve-cgi-bin other-vhosts-access-log
# Apache - Hide version
RUN sed -i "s/^ServerTokens OS$/ServerTokens Prod/g" /etc/apache2/conf-available/security.conf
# Apache - Avoid warning at startup
RUN echo "ServerName __default__" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername
# Apache- Prepare to be run as non root user
RUN mkdir -p /var/lock/apache2 \
    && chgrp -R 0 /run /var/lock/apache2 /var/log/apache2 \
    && chmod -R g=u /etc/passwd /run /var/lock/apache2 /var/log/apache2
RUN rm -f /var/log/apache2/*.log \
    && ln -s /proc/self/fd/2 /var/log/apache2/error.log \
    && ln -s /proc/self/fd/1 /var/log/apache2/access.log
RUN sed -i -e 's/80/8080/g' -e 's/443/8443/g' /etc/apache2/ports.conf
EXPOSE 8080 8443
# Apache - default virtualhost configuration
COPY files/000-default.conf /etc/apache2/sites-available/000-default.conf
# Cron - Create log directory
RUN mkdir -p /etc/cron.d /var/log/cron \        
    && chgrp -R 0 /etc/cron.d /var/log/cron \
    && chmod -R g=u /etc/cron.d /var/log/cron
# Cron - use supercronic (https://github.com/aptible/supercronic)
ENV SUPERCRONIC_VERSION=0.1.6
ENV SUPERCRONIC_SHA1SUM=c3b78d342e5413ad39092fd3cfc083a85f5e2b75
RUN curl -sSL "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-amd64" > "/usr/local/bin/supercronic" \
 && echo "${SUPERCRONIC_SHA1SUM}" "/usr/local/bin/supercronic" | sha1sum -c - \
 && chmod a+rx "/usr/local/bin/supercronic"
# Composer - make it usable by everyone
RUN chmod a+rx "/usr/local/bin/composer" \
    && mkdir -p /.composer \
    && chgrp -R 0 /.composer \
    && chmod -R g=u /.composer
# Php - Cache & Session support
RUN pecl install redis && docker-php-ext-enable redis
# Php - Yaml
RUN apt-get install -y --no-install-recommends libyaml-dev libyaml-0-2 && pecl install yaml-2.0.0 && docker-php-ext-enable yaml && apt-get remove -y libyaml-dev
# Php - GMP
RUN apt-get install -y --no-install-recommends libgmp-dev libgmpxx4ldbl && docker-php-ext-install gmp && apt-get remove -y libgmp-dev
# Php - Gearman
RUN apt-get install -y --no-install-recommends git unzip libgearman-dev libgearman7 && git clone https://github.com/wcgallego/pecl-gearman.git && cd pecl-gearman && phpize && ./configure && make && make install && cd - && rm -rf pecl-gearman && docker-php-ext-enable gearman && apt-get remove -y libgearman-dev
# Php - pcntl
RUN docker-php-ext-install pcntl
# Php - Mongodb with SSL
RUN apt-get install -y --no-install-recommends libssl1.0.2 libssl-dev && pecl uninstall mongodb && pecl install mongodb && apt-get remove -y libssl-dev
# Php - Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug
# Php - Sockets
RUN docker-php-ext-install sockets
# Php - Disable extension should be enable by user if needed
RUN rm -f /usr/local/etc/php/conf.d/docker-php-ext-exif.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-gd.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-gearman.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-mongodb.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-pcntl.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-pdo_pgsql.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-soap.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-sockets.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-zip.ini
COPY files/php.ini /usr/local/etc/php/conf.d/base.ini
# Php - Set default php.ini config variables (can be override at runtime)
ENV PHP_UPLOAD_MAX_FILESIZE 2m
ENV PHP_POST_MAX_SIZE 8m
ENV PHP_MAX_EXECUTION_TIME 30
ENV PHP_MEMORY_LIMIT 64m
ENV PHP_REALPATH_CACHE_SIZE 256k
ENV PHP_REALPATH_CACHE_TTL 3600
# Php - Opcache extension configuration
ENV PHP_OPCACHE_ENABLE 1
ENV PHP_OPCACHE_ENABLE_CLI 1
ENV PHP_OPCACHE_MEMORY 64
ENV PHP_OPCACHE_VALIDATE_TIMESTAMP 0
ENV PHP_OPCACHE_REVALIDATE_FREQ 600
ENV PHP_OPCACHE_MAX_ACCELERATED_FILES 7000
# System - Clean apt
RUN apt-get autoremove -y
COPY files/docker-entrypoint.sh /
COPY files/wait-for-it.sh /
RUN chmod a+rx /*.sh
WORKDIR /app
USER 1000
ENTRYPOINT ["/docker-entrypoint.sh"]
