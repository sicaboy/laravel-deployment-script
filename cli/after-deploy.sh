#!/bin/sh

# THIS SCRIPT IS SUPPOSED TO BE EXECUTED ON PROD SERVERS THROUGH DEPLOY.SH ON JENKINS
# Available Variables:
# TARGET_PROD_BUILD_DIR
# TARGET_PROD_WWW_BACKUP_DIR
# TARGET_PROD_WWW_DIR
# TARGET_PROD_ARTISAN_PATH

# # Keep .env
# cp $TARGET_PROD_WWW_DIR/.env ~/
# # Delete last backup
# echo "Removing: $TARGET_PROD_WWW_BACKUP_DIR"
# sudo rm -rf $TARGET_PROD_WWW_BACKUP_DIR
# # Move current www directory to last backup directory
# echo "Moving: $TARGET_PROD_WWW_DIR to $TARGET_PROD_WWW_BACKUP_DIR"
# sudo mv $TARGET_PROD_WWW_DIR $TARGET_PROD_WWW_BACKUP_DIR
# # Move this build directory to www directory
# echo "Moving: $TARGET_PROD_BUILD_DIR to $TARGET_PROD_WWW_DIR"
# sudo mv $TARGET_PROD_BUILD_DIR $TARGET_PROD_WWW_DIR
# # Move back .env
# mv ~/.env $TARGET_PROD_WWW_DIR

sudo rsync -avP $TARGET_PROD_BUILD_DIR $TARGET_PROD_WWW_DIR

# Log Related
# sudo mkdir /var/log/app
# sudo chown -R www-data:www-data /var/log/app
# sudo chmod -R a+rwx /var/log/app

# Go to www directory
echo "Go to: $TARGET_PROD_WWW_DIR"
cd $TARGET_PROD_WWW_DIR

echo "CHOWN"
sudo chown -R ubuntu:www-data $TARGET_PROD_WWW_DIR

mkdir vendor
mkdir bootstrap/cache
mkdir storage/logs
touch storage/logs/laravel.log

echo "Composer processing"
composer self-update
composer update
composer dump-autoload

echo "Artisan cleaning cache"
php $TARGET_PROD_ARTISAN_PATH cache:clear
echo "Artisan publishing vendor"
php $TARGET_PROD_ARTISAN_PATH vendor:publish
echo "Artisan migrate"
php $TARGET_PROD_ARTISAN_PATH migrate --force
echo "Static files processing"
# sudo npm update
# npm run prod
# sudo npm install gulp
# gulp --production
# @TODO: STATIC FILES TO S3 PROCESSING 
# php $TARGET_PROD_ARTISAN_PATH neo4j:migrate --database=neo4j

echo "CHGRP"
sudo chgrp -R www-data $TARGET_PROD_WWW_DIR/storage $TARGET_PROD_WWW_DIR/bootstrap/cache
echo "CHMOD"
sudo chmod -R ug+rwx $TARGET_PROD_WWW_DIR/storage $TARGET_PROD_WWW_DIR/bootstrap/cache

echo "Restarting services"
sudo service nginx restart
sudo service php7.0-fpm restart
echo "Artisan up"
php $TARGET_PROD_ARTISAN_PATH up