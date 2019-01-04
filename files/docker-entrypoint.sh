#!/bin/bash

# Set default username if not override
USER_NAME="${USER_NAME:-default}"

# Insert username into pwd
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME}:x:$(id -u):0:${USER_NAME} user:${HOME}:/sbin/bash" >> /etc/passwd
  fi
fi

echo "USER_NAME: $(id)"
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
else
	echo "PHP_ENABLE_EXTENSION: no extension to load at runtime"
fi

# Optimise opcache.max_accelerated_files, if settings is too small
nb_files=$(find . -type f -name '*.php' -print | wc -l)
if [ ${nb_files} -gt ${PHP_OPCACHE_MAX_ACCELERATED_FILES:-0} ]; then
	echo "Change PHP_OPCACHE_MAX_ACCELERATED_FILES from ${PHP_OPCACHE_MAX_ACCELERATED_FILES} to ${nb_files}"
	export PHP_OPCACHE_MAX_ACCELERATED_FILES=${nb_files}
fi

echo "PHP_OPCACHE_MAX_ACCELERATED_FILES: ${PHP_OPCACHE_MAX_ACCELERATED_FILES:-none}"

# Install dev dependencies of composer for test and dev, or if composer was not run before
if [ "${YII_ENV}" = "test" -o "${YII_ENV}" = "dev" ] || [ -f composer.json -a -z "$(ls -A vendor 2>/dev/null)" ]; then
	echo "Running composer update"
    composer update && rm -rf ${HOME}/.composer/cache
else
	echo "Composer update skipped (no YII_ENV: test/dev or no 'composer.json' file or 'vendor' directory already present"
fi

# Loop on WAIT_FOR_IT_LIST
if [ -n "${WAIT_FOR_IT_LIST}" ]; then
	for hostport in $(echo "${WAIT_FOR_IT_LIST}" | sed -e 's/,/ /g'); do
		/wait-for-it.sh -s -t 0 ${hostport}
	done
else
	echo "No WAIT_FOR_IT_LIST"
fi

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
	# Create a single file with all the crontab
	if [ -d "/etc/cron.d" ]; then
		# Remove the user name and merge into one file
		sed -r 's/(\s+)?\S+//6' /etc/cron.d/* > /etc/crontab
	fi
	if [ -n "${CRON_DEBUG}" -a "${CRON_DEBUG}" = "true" ] || [ "${YII_ENV}" = "dev" ]; then
		echo "Cron debug enabled"
		args="-debug"
	fi
	exec /usr/local/bin/supercronic ${args} /etc/crontab
else
	exec "apache2-foreground"
fi
