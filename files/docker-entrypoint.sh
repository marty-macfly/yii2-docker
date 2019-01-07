#!/bin/bash

if [ -f "/etc/environment" ]; then
    echo "Source /etc/environment"
    . /etc/environment
fi

basedir=$(dirname $0)

# Set default username if not override
USER_NAME="${USER_NAME:-default}"

# Insert username into pwd
if ! whoami &> /dev/null; then
  if [ -w "/etc/passwd" ]; then
    echo "${USER_NAME}:x:$(id -u):0:${USER_NAME} user:${HOME}:/sbin/bash" >> /etc/passwd
  fi
fi

echo "USER_NAME: $(id)"
APACHE_RUN_USER="${USER_NAME}"
echo "APACHE_RUN_USER: ${APACHE_RUN_USER}"

if [ -n "${PHP_TIMEZONE}"]; then
	PHP_TIMEZONE="${TZ}"
fi

echo "TZ: ${TZ}"
echo "PHP_TIMEZONE: ${PHP_TIMEZONE}"

# Loop on WAIT_FOR_IT_LIST
if [ -n "${WAIT_FOR_IT_LIST}" ]; then
	for hostport in $(echo "${WAIT_FOR_IT_LIST}" | sed -e 's/,/ /g'); do
		${basedir}/wait-for-it.sh -s -t 0 ${hostport}
	done
else
	echo "No WAIT_FOR_IT_LIST"
fi

# Enable xdebug by ENV variable (compatibility with upstream)
if [ 0 -ne "${PHP_ENABLE_XDEBUG:-0}" ] ; then
    PHP_ENABLE_EXTENSION="${PHP_ENABLE_EXTENSION},xdebug"
fi

# Enable extension by ENV variable
if [ -n "${PHP_ENABLE_EXTENSION}" ] ; then
	for extension in $(echo "${PHP_ENABLE_EXTENSION}" | sed -e 's/,/ /g'); do
    	if docker-php-ext-enable ${extension}; then
			echo "Enabled ${extension}"
		else
		    echo "Failed to enable ${extension}"
		fi
		echo ""
	done
else
	echo "PHP_ENABLE_EXTENSION: no extension to load at runtime"
fi

# Optimise opcache.max_accelerated_files, if not set
if [ -z "${PHP_OPCACHE_MAX_ACCELERATED_FILES}" ]; then
	echo "Set PHP_OPCACHE_MAX_ACCELERATED_FILES to PHP_OPCACHE_MAX_ACCELERATED_FILES_DEFAULT"
	export PHP_OPCACHE_MAX_ACCELERATED_FILES=${PHP_OPCACHE_MAX_ACCELERATED_FILES_DEFAULT:-7000}
fi

echo "PHP_OPCACHE_MAX_ACCELERATED_FILES: ${PHP_OPCACHE_MAX_ACCELERATED_FILES:-none}"

# Do database migration
if [ -n "${YII_DB_MIGRATE}" -a "${YII_DB_MIGRATE}" = "true" ]; then
	php yii migrate/up --interactive=0
else
	echo "YII_DB_MIGRATE: not set to 'true'"
fi

# Do rbac migration (add/Update/delete rbac permissions/roles)
if [ -n "${YII_RBAC_MIGRATE}" -a "${YII_RBAC_MIGRATE}" = "true" ]; then
    php yii rbac/load rbac.yml
else
	echo "YII_RBAC_MIGRATE: not set to 'true'"
fi

if [ -n "${1}" ]; then
	echo "Command line: ${@}"
else
	echo "No command line running Apache HTTPD server"
fi

if [ "${1}" = "yii" ]; then
	exec php ${@}
elif [ "${1}" = "cron" ]; then
	if [ -n "${CRON_DEBUG}" -a "${CRON_DEBUG}" = "true" ] || [ "${YII_ENV}" = "dev" ]; then
		echo "Cron debug enabled"
		args="-debug"
	fi
	exec /usr/local/bin/supercronic ${args} /etc/crontab
elif [ "${1}" = "bash" -o "${1}" = "php" -o "${1}" = "composer" ]; then
	exec ${@}
else
	exec "apache2-foreground"
fi
