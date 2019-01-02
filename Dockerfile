FROM yiisoftware/yii2-php:7.2-apache
# Fix upstream link error
RUN ([ -d /var/www/html ] && rm -rf /var/www/html && ln -s /app/web/ /var/www/html) || true
# Update embded package
RUN apt-get -y update \
    && apt-get -y upgrade
# Apache module
RUN a2enmod remoteip
ENV REMOTE_IP_INTERNAL_PROXY 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
# Hide apache version
RUN sed -i "s/^ServerTokens OS$/ServerTokens Prod/g" /etc/apache2/conf-available/security.conf
# apache configuration
COPY files/000-default.conf /etc/apache2/sites-available/000-default.conf
# Cache & Session support
RUN pecl install redis && docker-php-ext-enable redis
# Yaml
RUN apt-get install -y --no-install-recommends libyaml-dev libyaml-0-2 && pecl install yaml-2.0.0 && docker-php-ext-enable yaml && apt-get remove -y libyaml-dev
# GMP
RUN apt-get install -y --no-install-recommends libgmp-dev libgmpxx4ldbl && docker-php-ext-install gmp && apt-get remove -y libgmp-dev
# Gearman
RUN apt-get install -y --no-install-recommends git unzip libgearman-dev libgearman7 && git clone https://github.com/wcgallego/pecl-gearman.git && cd pecl-gearman && phpize && ./configure && make && make install && cd - && rm -rf pecl-gearman && docker-php-ext-enable gearman && apt-get remove -y libgearman-dev
# pcntl
RUN docker-php-ext-install pcntl
# Mongodb with SSL
RUN apt-get install -y --no-install-recommends libssl1.0.2 libssl-dev && pecl uninstall mongodb && pecl install mongodb && apt-get remove -y libssl-dev
# Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug
# Sockets
RUN docker-php-ext-install sockets
# Add cron
RUN apt-get install -y --no-install-recommends cron \
    && rm -f /etc/cron.*/* \
    && mkdir -p /var/log/cron
# Clean apt
RUN apt-get autoremove -y
# Disable extension should be enable by user if needed
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
# Set default php.ini config variables (can be override at runtime)
ENV PHP_TIMEZONE Europe/Paris
ENV PHP_UPLOAD_MAX_FILESIZE 2m
ENV PHP_POST_MAX_SIZE 8m
ENV PHP_MAX_EXECUTION_TIME 30
ENV PHP_MEMORY_LIMIT 64m
ENV PHP_REALPATH_CACHE_SIZE 256k
ENV PHP_REALPATH_CACHE_TTL 3600
# Opcache extension configuration
ENV PHP_OPCACHE_ENABLE 1
ENV PHP_OPCACHE_ENABLE_CLI 1
ENV PHP_OPCACHE_MEMORY 64
ENV PHP_OPCACHE_VALIDATE_TIMESTAMP 0
ENV PHP_OPCACHE_REVALIDATE_FREQ 600
ENV PHP_OPCACHE_MAX_ACCELERATED_FILES 7000
COPY files/docker-entrypoint.sh /
COPY files/wait-for-it.sh /
RUN chmod +x /*.sh
WORKDIR /app
ENTRYPOINT ["/docker-entrypoint.sh"]
