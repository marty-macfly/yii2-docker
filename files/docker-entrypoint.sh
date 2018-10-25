#!/bin/bash

# Optimise opcache.max_accelerated_files, if settings is too small
nb_files=$(find ~www-data -type f -name '*.php' -print | wc -l)
if [ ${nb_files} -gt ${PHP_OPCACHE_MAX_ACCELERATED_FILES} ]; then
	echo "Change PHP_OPCACHE_MAX_ACCELERATED_FILES from ${PHP_OPCACHE_MAX_ACCELERATED_FILES} to ${nb_files}"
	export PHP_OPCACHE_MAX_ACCELERATED_FILES=${nb_files}
fi

# Create Yii temporary directory
for dir in runtime web/runtime; do
	if [ ! -d "${dir}" ]; then
		echo "Create directory: ${dir}"
		mkdir -p "${dir}" && chmod 777 "${dir}"
	fi
done

tail -F runtime/logs/*.log /var/log/cron/*.log &

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
	# Add current environment to /etc/environment so it will be available for job in cron
	env > /etc/environment
	exec /usr/sbin/cron -f
else
	exec "apache2-foreground"
fi
