# Yii2 docker image

Inherit official [yii2-docker](https://github.com/yiisoft/yii2-docker) and based on the PHP Apache Debian version.

Change compare to upstream:

* Bind on port `8080` instead of `80`
* Doesn't run as root compatible with [openshift security policy](https://docs.openshift.com/container-platform/3.11/creating_images/guidelines.html)
 
# Entry-point

Entry-point script can run:
* start **Apache HTTPD** server (default behavior)
* **cron daemon** with environment variable properly setup
* [Yii CLI application](https://www.yiiframework.com/doc/guide/2.0/en/tutorial-console) with your custom arguments
* `bash`, `php` and `composer` command are also allowed

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
* gearman
* gmp (`*`)
* imagick
* intl (`*`)
* mongodb
* pcntl
* pdo_mysql
* pdo_pgsql
* soap
* sockets
* sodium (`*`)
* yaml (`*`)
* xdebug
* Zend OPcache (`*`)
* zip

If you want for your specific application to enable one of them just do:

```
docker-php-ext-enable extension-name
```

## Image Configuration at buildtime

With docker build arguments.

### System configuration

* **TZ**: System timezone will by application for cron and logs (default: `Europe/Paris`)

### Cron configuration

We're using [supercronic](https://github.com/aptible/supercronic) as cron dameon. You can put your cronfile in:
*  `/etc/cron.d/` in the normal cron format '`minute` `hour` `day of month` `month` `day of week` `user` (NB: user will not be taken in consideration in our cron is not run as root)
* or create the file `/etc/crontab` in [supercronic supported format](https://github.com/gorhill/cronexpr).

### Yii configuration

* **YII_ENV**: [Environment constants](http://www.yiiframework.com/doc-2.0/guide-concept-configurations.html#environment-constants) can be `prod`, `dev`, `test` (default: `prod`). In `test` and `dev` composer development dependencies are installed (`gii`, `codeception`, ...) at buildtime.

### Documentation Generation configuration

You can generate a static documentation with [daux.io](https://github.com/dauxio/daux.io) to be include in your application, if you've got a documentation directory inside your code.

* **DOC_GENERATE**: Do you want to generate the static doc (default: `yes`).
* **DOC_DIR_SRC**: Source directory of your documentation inside the `/app/` (default: `docs`).
* **DOC_DIR_DST**: Destination directory of the generated documentation in `/app/web/` (default: `doc`).

## Image Configuration at runtime

With environment variables.

### Enable PHP extensions/modules

You can enable extension at runtime with the environment variable `PHP_ENABLE_EXTENSION`, you can provide a list of extension by separating them with with comma (`,`).

```
PHP_ENABLE_EXTENSION=gd,exif
```

### Apache HTTPD configuration

* **REMOTE_IP_HEADER**: Set `RemoteIPHeader` directive of the [remote_ip module](https://httpd.apache.org/docs/trunk/mod/mod_remoteip.html) (default: `X-Forwarded-For`)
* **REMOTE_IP_TRUSTED_PROXY**: Set `RemoteIPtrustedProxy` directive of the [remote_ip module](https://httpd.apache.org/docs/trunk/mod/mod_remoteip.html) (default: `10.0.0.0/8 172.16.0.0/12 192.168.0.0/16`)
* **REMOTE_IP_INTERNAL_PROXY**: Set `RemoteIPInternalProxy` directive of the [remote_ip module](https://httpd.apache.org/docs/trunk/mod/mod_remoteip.html) (default: `10.0.0.0/8 172.16.0.0/12 192.168.0.0/16`)

### Cron configuration

* **CRON_DEBUG**: Enable debug mode of [supercronic](https://github.com/aptible/supercronic).

### PHP configuration

You can override some PHP configuration setting by defining the following environment variable:

#### General confguration

* **PHP_TIMEZONE**: [date.timezone](http://php.net/manual/en/datetime.configuration.php#ini.date.timezone) (default: `$TZ`)
* **PHP_UPLOAD_MAX_FILESIZE**: [upload_max_filesize](http://php.net/manual/en/ini.core.php#ini.upload-max-filesize) (default: `2m`)
* **PHP_POST_MAX_SIZE**: [post_max_size](http://php.net/manual/en/ini.core.php#ini.post-max-size) (default: `8m`)
* **PHP_MAX_EXECUTION_TIME**: [max_execution_time](http://php.net/manual/en/info.configuration.php#ini.max-execution-time) (default: `30`)
* **PHP_MEMORY_LIMIT**: [memory_limit](http://php.net/manual/en/ini.core.php#ini.memory-limit) (default: `64m`)
* **PHP_REALPATH_CACHE_SIZE**: [realpath_cache_size](http://php.net/manual/en/ini.core.php#ini.realpath-cache-size) (default: `256k`)
* **PHP_REALPATH_CACHE_TTL**: [realpath_cache_ttl](http://php.net/manual/en/ini.core.php#ini.realpath-cache-ttl) (default: `3600`)

#### Opcache configuration

* **PHP_OPCACHE_ENABLE**: [opcache.enable](http://php.net/manual/en/opcache.configuration.php#ini.opcache.enable) enable Opcache (default: `1` = On)
* **PHP_OPCACHE_ENABLE_CLI**: [opcache.enable_cli](http://php.net/manual/en/opcache.configuration.php#ini.opcache.enable-cli) enable opcache for PHP in CLI (default: `1` = On)
* **PHP_OPCACHE_MEMORY**: [opcache.memory_consumption](http://php.net/manual/en/opcache.configuration.php#ini.opcache.memory-consumption) (default: `64m`)
* **PHP_OPCACHE_VALIDATE_TIMESTAMP**: [opcache.validate_timestamps](http://php.net/manual/en/opcache.configuration.php#ini.opcache.validate-timestamps) (default: `0` = Off)
* **PHP_OPCACHE_REVALIDATE_FREQ**: [opcache.revalidate_freq](http://php.net/manual/en/opcache.configuration.php#ini.opcache.revalidate-freq) (default: `600` seconds)
* **PHP_OPCACHE_MAX_ACCELERATED_FILES**: [opcache.max_accelerated_files](http://php.net/manual/en/opcache.configuration.php#ini.opcache.max-accelerated-files) (default: `7000` adjusted at runtime by the start script)
