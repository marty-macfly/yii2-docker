#!/bin/bash -x

# Insert username into pwd
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
	if [ -n "${USER_NAME}"]; then
		USER_NAME="default"
	fi
    echo "${USER_NAME}:x:$(id -u):0:${USER_NAME} user:${HOME}:/sbin/bash" >> /etc/passwd
	echo "USER_NAME: ${USER_NAME}"
  fi
fi

APACHE_RUN_USER="${USER_NAME}"
echo "APACHE_RUN_USER: ${APACHE_RUN_USER}"

# Set the proper timezone
if [ -n "${TZ}" ]; then
	ln -snf "/usr/share/zoneinfo/$TZ" "/etc/localtime"
	echo "$TZ" > /etc/timezone

	if [ -n "${PHP_TIMEZONE}"]; then
		PHP_TIMEZONE="${TZ}"
	fi
fi

echo "TZ: ${TZ}"
echo "PHP_TIMEZONE: ${PHP_TIMEZONE}"

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
fi

# Optimise opcache.max_accelerated_files, if settings is too small
nb_files=$(find . -type f -name '*.php' -print | wc -l)
if [ ${nb_files} -gt ${PHP_OPCACHE_MAX_ACCELERATED_FILES} ]; then
	echo "Change PHP_OPCACHE_MAX_ACCELERATED_FILES from ${PHP_OPCACHE_MAX_ACCELERATED_FILES} to ${nb_files}"
	export PHP_OPCACHE_MAX_ACCELERATED_FILES=${nb_files}
fi

# Install dev dependencies of composer for test and dev, or if composer was not run before
if [ "${YII_ENV}" = "test" -o "${YII_ENV}" = "dev" ] || [ -f composer.json -a -z "$(ls -A vendor 2>/dev/null)" ]; then
    composer update
fi

# Loop on WAIT_FOR_IT_LIST
if [ -n "${WAIT_FOR_IT_LIST}" ]; then
	for hostport in $(echo "${WAIT_FOR_IT_LIST}" | sed -e 's/,/ /g'); do
		/wait-for-it.sh -s -t 0 ${hostport}
	done
fi

# Do database migration
if [ -n "${YII_DB_MIGRATE}" -a "${YII_DB_MIGRATE}" = "true" ]; then
	php yii migrate/up --interactive=0
fi

# Do rbac migration (add/Update/delete rbac permissions/roles)
if [ -n "${YII_RBAC_MIGRATE}" -a "${YII_RBAC_MIGRATE}" = "true" ]; then
    php yii rbac/load rbac.yml
fi

if [ -n "${1}" ]; then
	echo "Command line: ${@}"
else
	echo "No command line running Apache HTTPD server"
fi

if [ "${1}" = "yii" ]; then
	exec php ${@}
elif [ "${1}" = "cron" ]; then
	exec /usr/local/bin/supercronic /etc/cron.d/*
else
	exec "apache2-foreground"
fi
