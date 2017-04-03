#!/bin/sh
LOCAL_DEPLOY_SCRIPT_DIR=$(pwd)

# JENKINS VARIABLE OR DIRECT SETUP BELOW:
MAINTENANCE="Y"
PEM_PATH="~/Desktop/awsslj.pem"
SSH_USERNAME="ubuntu"
TARGET_HOSTS="ec2-54-252-153-210.ap-southeast-2.compute.amazonaws.com"

GIT_REPOSITORY="https://github.com/sicaboy/api-parcelf.git"
GIT_BRANCH="master"
LOCAL_TEMP_WORKSPACE="/tmp/deploy_git"
TARGET_PROD_BUILD_DIR="~/builds_www"
TARGET_PROD_WWW_BACKUP_DIR="~/builds_www_backup"
TARGET_PROD_WWW_DIR="/var/www/api-parcelf"
TARGET_PROD_ARTISAN_PATH="$TARGET_PROD_WWW_DIR/artisan"

# SET ALL PROD SERVERS WITH MAINTENANCE PAGE
echo "Will set maintenance page: $MAINTENANCE"
if [ "$MAINTENANCE" = "Y" ]; then
    echo "Setting maintenance page..."
    for HOST in $TARGET_HOSTS
    do
        #ssh -i $PEM_PATH $SSH_USERNAME@$HOST "if [ -f $TARGET_PROD_ARTISAN_PATH ]; then sudo ln -s /var/www/down.html /var/www/maintenance.html; fi;"
        ssh -i $PEM_PATH $SSH_USERNAME@$HOST "if [ -f $TARGET_PROD_ARTISAN_PATH ]; then sudo php $TARGET_PROD_ARTISAN_PATH down; fi;"
        echo $HOST
    done
fi

# Fetch files from Git
if [ -d "$LOCAL_TEMP_WORKSPACE" ]; then
    rm -rf $LOCAL_TEMP_WORKSPACE
fi
git clone $GIT_REPOSITORY $LOCAL_TEMP_WORKSPACE
cd $LOCAL_TEMP_WORKSPACE
git reset --hard
git pull origin $GIT_BRANCH
git checkout $GIT_BRANCH

#Clean git files
echo "Removing $LOCAL_TEMP_WORKSPACE/.git"
rm -rf $LOCAL_TEMP_WORKSPACE/.git


for HOST in $TARGET_HOSTS
do
  echo "Preparing $HOST"

  # MAKE DIRECTORIES CHANGE OWNERSHIP SO RSYNC CAN WRITE
  ssh -i $PEM_PATH $SSH_USERNAME@$HOST "if [ ! -d "$TARGET_PROD_BUILD_DIR" ]; then sudo mkdir $TARGET_PROD_BUILD_DIR; fi; sudo chown -R $SSH_USERNAME $TARGET_PROD_BUILD_DIR"

 # RSYNC
  rsync -az -e "ssh -i $PEM_PATH" $LOCAL_TEMP_WORKSPACE/ $SSH_USERNAME@$HOST:$TARGET_PROD_BUILD_DIR

 # CHANGE CONFIGS ETC
  echo "Copy $LOCAL_DEPLOY_SCRIPT_DIR/after-deploy.sh to remote server"
  scp -i $PEM_PATH  $LOCAL_DEPLOY_SCRIPT_DIR/after-deploy.sh $SSH_USERNAME@$HOST:/tmp/after-deploy.sh
  
  echo "Executing after-deploy.sh on remote server"
  #ssh -i $PEM_PATH $SSH_USERNAME@$HOST "export TARGET_PROD_BUILD_DIR=$TARGET_PROD_BUILD_DIR; export TARGET_PROD_WWW_BACKUP_DIR=$TARGET_PROD_WWW_BACKUP_DIR; export TARGET_PROD_WWW_DIR=$TARGET_PROD_WWW_DIR; export TARGET_PROD_ARTISAN_PATH=$TARGET_PROD_ARTISAN_PATH; sudo -E sh /tmp/after-deploy.sh;"
  ssh -i $PEM_PATH $SSH_USERNAME@$HOST "export TARGET_PROD_BUILD_DIR=$TARGET_PROD_BUILD_DIR; export TARGET_PROD_WWW_BACKUP_DIR=$TARGET_PROD_WWW_BACKUP_DIR; export TARGET_PROD_WWW_DIR=$TARGET_PROD_WWW_DIR; export TARGET_PROD_ARTISAN_PATH=$TARGET_PROD_ARTISAN_PATH; sh /tmp/after-deploy.sh;"

done
