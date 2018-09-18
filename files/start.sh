#!/bin/bash
[ -n "${DB_TYPE}" ] && /wait-for-it.sh -s ${DB_HOST}:${DB_PORT}
[ -n "${REDIS_HOST}" ] && /wait-for-it.sh -t 0 -s ${REDIS_HOST}:${REDIS_PORT:-6379}

# Optimise opcache.max_accelerated_files, if settings is too small
nb_files=$(find ~www-data -type f -name '*.php' -print | wc -l)
if [ ${nb_files} -gt ${PHP_OPCACHE_MAX_ACCELERATED_FILES} ]; then
	echo "Change PHP_OPCACHE_MAX_ACCELERATED_FILES from ${PHP_OPCACHE_MAX_ACCELERATED_FILES} to ${nb_files}"
	export PHP_OPCACHE_MAX_ACCELERATED_FILES=${nb_files}
fi

if [ -n "${DB_TYPE}" ]; then
	su www-data -s /bin/bash -c '[ -d migrations ] && php yii migrate/up --interactive=0'
fi

if [ "${MOD}" = "cli" ]; then
    su www-data -s /bin/bash -c "php yii ${CLI_CMD:-help}"
else
    ## Add/Update rbac permissions/roles
    su www-data -s /bin/bash -c 'php yii rbac/load rbac.yml'
    ## Create log file
    su www-data -s /bin/bash -c 'mkdir -p runtime/logs && touch runtime/logs/app.log'
    tail -F runtime/logs/*.log &
    exec "apache2-foreground"
fi
