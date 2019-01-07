#!/bin/bash

if [ $(id -u) -ne 0 ]; then
    echo "Script should be run as root during buildtime."
    exit 1
else
    echo "Running as root that's cool :)"
fi

# System - set exec on scripts in /docker-bin/
echo "Set exec mode on '/docker-bin/*.sh'"
chmod a+rx /docker-bin/*.sh 

# System - set the proper timezone
if [ -n "${TZ}" ]; then
	ln -snf "/usr/share/zoneinfo/$TZ" "/etc/localtime"
	echo "$TZ" > /etc/timezone
fi

tz=$(ls -l "/etc/localtime" | awk '{print $NF}' | sed -e 's#/usr/share/zoneinfo/##g')
echo "TZ: ${TZ:-default} (effective ${tz})"

# Cron - Merge all files in /etc/cron.d into /etc/crontab
if [ -d "/etc/cron.d" ]; then
	# Remove the user name and merge into one file
    echo "Merging cron in '/etc/cron.d' into '/etc/crontab'"
	sed -r 's/(\s+)?\S+//6' /etc/cron.d/* > /etc/crontab
fi

if [ -f "/etc/crontab" ]; then
    echo "Set mode g=rw on '/etc/crontab'"
    chmod 664 /etc/crontab
fi

APP_DIR="${APP_DIR:-.}"
echo -e "\nAPP_DIR: ${APP_DIR}\n"
cd ${APP_DIR}
for file in .git .gitlab*; do
    if [ -e "${file}" ]; then
        echo -e "\tCleanup: ${file}"
        rm -rf ${file}
    fi
done

if [ -d "tests" ]; then
    echo -e "\tSet exec mode on 'test/*.sh'"
    chmod a+rx tests/*.sh 
fi

echo -e "\tSet '${APP_DIR}' mode ugo=r for file and ugo=rx for directory"
find . -path ./vendor -prune -o -type d -exec chmod 555 {} \;
find . -path ./vendor -prune -o -type f -exec chmod 444 {} \;

for dir in runtime web/assets web/runtime tests/_output tests/_support/_generated; do
    if [ ! -d "${dir}" ]; then
        echo -e "\tCreate directory: ${dir}"
        mkdir -p "${dir}"
    fi
    echo -e "\tSet mode ug=rwx on directory: ${dir}"
    chmod 775 "${dir}"
done

# Install/Update composer
if [ -f "composer.json" ]; then
    echo -e "\tYII_ENV: ${YII_ENV:-not set}"
    # Install dev dependencies if test and dev
    if [ "${YII_ENV}" != "test" -a "${YII_ENV}" != "dev" ]; then
        args="--no-dev"
    fi
    echo -e "\tRunning composer ${args}"
    composer ${args} -o update
    rm -rf ${HOME}/.composer
fi

# Optimise opcache.max_accelerated_files, if settings is too small
nb_files=$(find . -type f -name '*.php' -print | wc -l)
if [ ${nb_files} -gt 0 ]; then
    echo "Set PHP_OPCACHE_MAX_ACCELERATED_FILES_DEFAULT to ${nb_files}"
	echo "export PHP_OPCACHE_MAX_ACCELERATED_FILES_DEFAULT=${nb_files}" >> /etc/environment
fi

cd - > /dev/null
echo 