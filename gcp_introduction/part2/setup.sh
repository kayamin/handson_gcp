#!/bin/bash

sudo apt-get -y install \
git python-pip python-dev python-flask python-wtforms python-arrow \
python-flask-sqlalchemy python-pymysql python-flaskext.wtf

sudo pip install --upgrade setuptools
sudo pip install --upgrade gcloud

# 何故か以降のコマンドは無視されるもしくは一部のみ実行されること等ある．理由は不明
sudo mkdir /app
sudo chmod 777 /app
cd /app
git clone https://github.com/asashiho/gcp-compute-engine
cd gcp-compute-engine
sudo app_v1/install.sh

# CloudSQL Proxy をインストール
cd /app/gcp-compute-engine
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
mv cloud_sql_proxy.linux.amd64 cloud_sql_proxy
chmod +x cloud_sql_proxy
sudo mkdir /opt/cloudsqlproxy
sudo mv cloud_sql_proxy /opt/cloudsqlproxy/

# CloudSQLProxy が使用するUNIXソケットを格納するディレクトリを作成
sudo mkdir /cloudsql
sudo chmod 777 /cloudsql
