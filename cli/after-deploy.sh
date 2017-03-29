#!/bin/sh

# THIS SCRIPT IS SUPPOSED TO BE EXECUTED ON PROD SERVERS THROUGH DEPLOY.SH ON JENKINS
# Available Variables:
# TARGET_PROD_BUILD_DIR
# TARGET_PROD_WWW_BACKUP_DIR
# TARGET_PROD_WWW_DIR
# TARGET_PROD_ARTISAN_PATH

# Delete last backup
rm -rf $TARGET_PROD_WWW_BACKUP_DIR
# Move current www directory to last backup directory
mv $TARGET_PROD_WWW_DIR $TARGET_PROD_WWW_BACKUP_DIR
# Move this build directory to www directory
mv $TARGET_PROD_BUILD_DIR $TARGET_PROD_WWW_DIR
# Remove this build directory
rm $TARGET_PROD_BUILD_DIR

# Log Related
# sudo mkdir /var/log/app
# sudo chown -R www-data:www-data /var/log/app
# sudo chmod -R a+rwx /var/log/app

# Go to www directory
cd $TARGET_PROD_WWW_DIR
php artisan down
sudo chown -R www-data:www-data $TARGET_PROD_WWW_DIR
sudo chgrp -R www-data $TARGET_PROD_WWW_DIR/storage $TARGET_PROD_WWW_DIR/bootstrap/cache
sudo chmod -R ug+rwx $TARGET_PROD_WWW_DIR/storage $TARGET_PROD_WWW_DIR/bootstrap/cache
composer self-update
composer update
composer dump-autoload
php artisan cache:clear
php artisan vendor:publish
php artisan migrate
npm update
# npm run prod
gulp --production
# @TODO: STATIC FILES TO S3 PROCESSING 
# php artisan neo4j:migrate --database=neo4j
sudo service nginx restart
sudo service php7.0-fpm restart
php artisan up