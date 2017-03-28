#!/bin/sh

# JENKINS VARIABLE OR DIRECT SETUP BELOW:
MAINTENANCE="Y"
PEM_PATH="~/Desktop/awsslj.pem"
SSH_USERNAME="ubuntu"
TARGET_HOSTS="ec2-54-252-153-210.ap-southeast-2.compute.amazonaws.com"

GIT_REPOSITORY="https://github.com/sicaboy/api-parcelf.git"
GIT_BRANCH="master"
LOCAL_TEMP_WORKSPACE="/tmp/deploy_git"
TARGET_PROD_BUILD_DIR="~/builds/www_temp"
TARGET_PROD_WWW_DIR="/var/www/api-parcelf"
TARGET_PROD_ARTISAN_PATH="$TARGET_PROD_WWW_DIR/artisan"


# SET ALL PROD SERVERS WITH MAINTENANCE PAGE
echo "Will set maintenance page: $MAINTENANCE"
if [ "$MAINTENANCE" = "Y" ]; then
    echo "Setting maintenance page..."
    for HOST in $TARGET_HOSTS
    do
        #ssh -i $PEM_PATH $SSH_USERNAME@$HOST "if [ -f $TARGET_PROD_ARTISAN_PATH ]; then sudo ln -s /var/www/down.html /var/www/maintenance.html; fi;"
        ssh -i $PEM_PATH $SSH_USERNAME@$HOST "if [ -f $TARGET_PROD_ARTISAN_PATH ]; then php $TARGET_PROD_ARTISAN_PATH down; fi;"
        echo $HOST
    done
fi

# Fetch files from Git
if [ -d "$LOCAL_TEMP_WORKSPACE" ]; then
    rm -R $LOCAL_TEMP_WORKSPACE
fi
git clone $GIT_REPOSITORY $LOCAL_TEMP_WORKSPACE
cd $LOCAL_TEMP_WORKSPACE
git reset --hard
git pull origin $GIT_BRANCH
git checkout $GIT_BRANCH

#Clean git files
echo "Removing $LOCAL_TEMP_WORKSPACE/.git"
rm -R $LOCAL_TEMP_WORKSPACE/.git

for HOST in $TARGET_HOSTS
do
  echo "Preparing $HOST"

  # MAKE DIRECTORIES CHANGE OWNERSHIP SO RSYNC CAN WRITE
  ssh -i $PEM_PATH $SSH_USERNAME@$HOST "if [ ! -d "$TARGET_PROD_BUILD_DIR" ]; then sudo mkdir $TARGET_PROD_BUILD_DIR; fi; sudo chown -R $SSH_USERNAME $TARGET_PROD_BUILD_DIR"

 # RSYNC
  rsync -az -e "ssh -i $PEM_PATH" $LOCAL_TEMP_WORKSPACE/ $SSH_USERNAME@$HOST:$TARGET_PROD_BUILD_DIR

 #CHANGE CONFIGS ETC
  ssh -i $PEM_PATH $SSH_USERNAME@$HOST "export DEST=$TARGET_PROD_BUILD_DIR; export BASE_DOMAIN=$BASE_DOMAIN;export SUBPORTAL=$SUBPORTAL;export SUBPUBLIC=$SUBPUBLIC;export SUBSTATIC=$SUBSTATIC; export SUBUPLOAD=$SUBUPLOAD;cd /home/tallcat; sudo -E $TARGET_PROD_BUILD_DIR/cli/after-deploy.sh;"

done