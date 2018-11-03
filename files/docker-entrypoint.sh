#!/bin/bash

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
if [ "${YII_ENV}" = "test" -o "${YII_ENV}" = "dev" -o -z "$(ls -A vendor)" ]; then
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
	su www-data -s /bin/bash -c 'php yii migrate/up --interactive=0'
fi

# Do rbac migration (add/Update/delete rbac permissions/roles)
if [ -n "${YII_RBAC_MIGRATE}" -a "${YII_RBAC_MIGRATE}" = "true" ]; then
    su www-data -s /bin/bash -c 'php yii rbac/load rbac.yml'
fi

if [ -n "${1}" ]; then
	echo "Command line: ${@}"
else
	echo "No command line running Apache HTTPD server"
fi

if [ "${1}" = "yii" ]; then
	cmd="php ${@}"
	su www-data -s /bin/bash -c "${cmd}"
elif [ "${1}" = "cron" ]; then
	tail -F /var/log/cron/*.log 2>/dev/null &
	# Add current environment to /etc/environment so it will be available for job in cron
	env > /etc/environment
	exec /usr/sbin/cron -f
else
	exec "apache2-foreground"
fi
