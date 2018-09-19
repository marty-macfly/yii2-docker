# Yii2 docker image

Inherit official [yii2-docker](https://github.com/yiisoft/yii2-docker) and based on the PHP Apache Debian version.

# Entry-point

Entry-point script can run:
* start **Apache HTTPD** server (default behavior)
* **cron daemon** with environment variable properly setup
* [Yii CLI application](https://www.yiiframework.com/doc/guide/2.0/en/tutorial-console) with your custom arguments

The entry-point script is also providing those helpers:

## Wait for a list of service availability

Before running your service you may be need to wait for other to be up and listening (example wait for you database server to be up and running on port 3306). You can provide the environment variable `WAIT_FOR_IT_LIST` with the list of service to test before starting up the application.

If you want to wait for a mysql server on port 3306 and an SMTP server on port 25, just do:

```
WAIT_FOR_IT_LIST=mysql:3306,smtp:25
```

## Database migration

May be you want you container to do database schema migration before starting up, just set `YII_DB_MIGRATE` to `true` for more detail refer to [Yii2 databse migration](https://www.yiiframework.com/doc/guide/2.0/en/db-migrations).

## Rbac static role and permissions management

If you want to create your list of static role and permission on your authManager, you can set `YII_RBAC_MIGRATE` to `true` for more detail refer to [macfly/yii2-rbac-cli](https://github.com/marty-macfly/yii2-rbac-cli).

# PHP module

List of already embed modules (the one with a (`*`) are loaded by default):

* bcmath (`*`)
* exif
* gd
* imagick
* intl (`*`)
* gearman
* gmp (`*`)
* mongodb
* pcntl
* pdo_mysql
* pdo_pgsql
* soap
* sodium (`*`)
* yaml (`*`)
* xdebug
* Zend OPcache (`*`)
* zip

If you want for your specific application to enable one of them just do:

```
docker-php-ext-enable extension-name
```

# PHP configuration

You can override some PHP configuration setting by defining the following environment variable:

## General confguration

* **PHP_TIMEZONE**: timezone (default: `Europe/Paris`)
* **PHP_UPLOAD_MAX_FILESIZE**: (default: `2m`)
* **PHP_POST_MAX_SIZE**: (default: `8m`)
* **PHP_MEMORY_LIMIT**: (default: `64m`)
* **PHP_REALPATH_CACHE_SIZE**: (default: `256k`)
* **PHP_REALPATH_CACHE_TTL**: (default: `3600`)

## Opcache configuration

* **PHP_OPCACHE_ENABLE**:  enable Opcache (default: `1` = On)
* **PHP_OPCACHE_ENABLE_CLI**: enable opcache for PHP in CLI (default: `1` = On)
* **PHP_OPCACHE_MEMORY**: (default: `64m`)
* **PHP_OPCACHE_VALIDATE_TIMESTAMP**: (default : `0` = Off)
* **PHP_OPCACHE_MAX_ACCELERATED_FILES**: (default: `7000` adjusted at runtime by the start script)
