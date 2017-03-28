#!/bin/sh

# THIS SCRIPT IS SUPPOSED TO BE EXECUTED ON PROD SERVERS THROUGH DEPLOY.SH ON JENKINS

cd /home/tallcat
rm -rf builds/www_old
mv builds/www_v1 builds/www_old
mv $DEST builds/www_v1
rm www_v1
ln -s builds/www_v1 /home/tallcat/www_v1
sudo mkdir /var/log/tallcat
sudo chown -R www-data:www-data /var/log/tallcat
sudo chmod -R a+rwx /var/log/tallcat

php www_v1/cli/minify-tpl.php

mkdir www_v1/app/logs
sudo touch www_v1/app/logs/portal.log
sudo chown -R www-data:www-data builds/www_v1
sudo chmod -R a+w builds/www_v1/app/logs
sudo chown -R www-data:www-data www_v1
sudo chmod -R a+w www_v1/app/logs

CACHE_PATH='www_v1/app/cache'
mkdir $CACHE_PATH
sudo chown -R www-data:www-data $CACHE_PATH
sudo chmod 777 $CACHE_PATH

LOG_PATH='www_v1/app/storage/logs/'
mkdir $LOG_PATH
sudo chown -R www-data:www-data $LOG_PATH
sudo chmod 777 $LOG_PATH
# Need to restart to avoid error in php path cache


mkdir www_v1/app/storage
mkdir www_v1/app/storage/framework
mkdir www_v1/app/storage/logs
mkdir www_v1/app/storage/api
mkdir www_v1/app/storage/api/framework
mkdir www_v1/app/storage/api/logs

sudo chown www-data:www-data -hR www_v1/app/storage
sudo chmod a+w -R www_v1/app/storage
service apache2 restart
cd www_v1
composer self-update
composer update
composer dump-autoload
php artisan cache:clear
php artisan vendor:publish --force
# php artisan migrate --force
php artisan migrate
# php artisan neo4j:migrate --database=neo4j
php artisan up