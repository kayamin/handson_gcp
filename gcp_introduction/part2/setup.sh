#!/bin/bash

sudo apt-get -y install \
git python-pip python-dev python-flask python-wtforms python-arrow \
python-flask-sqlalchemy python-pymysql python-flaskext.wtf

sudo pip install --upgrade setuptools
sudo pip install --upgrade gcloud

#git clone https://github.com/asashiho/gcp-compute-engine