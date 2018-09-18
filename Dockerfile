FROM php:apache
RUN apt-get update
# Bcmath & opcache
RUN apt-get install -y --no-install-recommends vim net-tools && a2enmod rewrite && docker-php-ext-install bcmath && docker-php-ext-install opcache
# Multi-langue
RUN apt-get install -y --no-install-recommends libicu57 libicu-dev && docker-php-ext-install intl && apt-get remove -y libicu-dev
# Redis
RUN pecl install redis && docker-php-ext-enable redis
# Imagick docker-php-ext-enable imagick
RUN apt-get install -y --no-install-recommends libmagick++-6.q16-7 libmagick++-dev && pecl install imagick && apt-get remove -y libmagick++-dev
# DB mysql
#RUN docker-php-ext-install pdo_mysql
# Yaml
#RUN apt-get install -y --no-install-recommends libyaml-dev libyaml-0-2 && pecl install yaml-2.0.0 && docker-php-ext-enable yaml && apt-get remove -y libyaml-dev
# pcntl
#RUN docker-php-ext-install pcntl
# Composer
RUN apt-get install -y --no-install-recommends libssl1.0.2 libssl-dev wget git unzip && wget -O composer-setup.php https://getcomposer.org/installer && php composer-setup.php --filename=composer --install-dir=/usr/bin && rm -f composer-setup.php
RUN apt-get autoremove -y
COPY files/php.ini /usr/local/etc/php/
# Set default php.ini config variables (can be override at runtime)
ENV PHP_TIMEZONE Europe/Paris
ENV PHP_UPLOAD_MAX_FILESIZE 2m
ENV PHP_POST_MAX_SIZE 8m
ENV PHP_MEMORY_LIMIT 64m
ENV PHP_REALPATH_CACHE_SIZE 256k
ENV PHP_REALPATH_CACHE_TTL 3600
# Opcache extension configuration
ENV PHP_OPCACHE_ENABLE 1
ENV PHP_OPCACHE_ENABLE_CLI 1
ENV PHP_OPCACHE_MEMORY 64
ENV PHP_OPCACHE_VALIDATE_TIMESTAMP 0
ENV PHP_OPCACHE_MAX_ACCELERATED_FILES 7000
COPY files/apache.conf /etc/apache2/sites-available/000-default.conf
COPY files/start.sh /
COPY files/wait-for-it.sh /
RUN chmod +x /*.sh
CMD ["/start.sh"]
