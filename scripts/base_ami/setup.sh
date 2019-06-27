#!/bin/bash

echo "***[Updating OS]***"
sudo yum -y update

echo "***[Installing Development Tools]***"
sudo yum groupinstall -y 'development tools'
sudo yum install -y zlib-dev openssl-devel sqlite-devel bzip2-devel

echo "***[Installing Python36]***"
sudo yum install -y python36u python36u-libs python36u-devel python36u-pip python36-setuptools

echo "***[Installing Node v12]***"
curl -sL https://rpm.nodesource.com/setup_12.x | sudo bash -
sudo yum install nodejs -y

echo "***[Install Nginx]***"
sudo yum install nginx
echo "***[Install Git]***"
sudo yum install git -y 
echo "***[Versions]***"
echo "Python version $(python3.6 --version)"
echo "Node version $(node --version)"
echo "NPM version $(npm --version)"
echo "PIP version $(python36 -m pip --version )"


echo "***[Creating log dirs]***"
cd /var/log/ && sudo mkdir -p app_logs/{gunicorn,supervisor,app,celery,memcached}
# TODO: create error log files within write access 

echo "***[Creating Main App Dir]***"
sudo mkdir /srv/app/ && cd /srv/app/

# TODO: fetch secrets files

echo "***[Installing & Creating env]***"
sudo python36 -m pip install virtualenv

sudo virtualenv -p python36 venv
cd /srv/app/venv && source ./bin/activate

echo "***[Installing app modules]***"
sudo pip install gunicorn  
sudo pip install supervisor

