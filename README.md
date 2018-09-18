# Yii2 docker image

Inherit official [yii2-docker](https://github.com/yiisoft/yii2-docker) and based on the php apache debian version.

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

# ImageMagic

If you want to enable ImageMagic you just need to add in your Dockerfile

```
docker-php-ext-enable imagick
```


# yaml

```
docker-php-ext-enable yaml
```
