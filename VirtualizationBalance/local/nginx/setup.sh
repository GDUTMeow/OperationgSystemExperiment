#!/bin/bash

set -e

sudo dnf install -y openssl-devel
wget https://nginx.org/download/nginx-1.31.2.tar.gz -O nginx.tar.gz
tar -zxvf nginx.tar.gz
cd nginx-1.31.2
sudo mkdir -p /usr/local/nginx
sudo mkdir -p /usr/local/nginx/sbin
./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_stub_status_module && make && sudo make install
sudo ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin
sudo cp nginx.conf /usr/local/nginx/conf/nginx.conf
sudo nginx -t
sudo nginx -s reload

rm -rf nginx.tar.gz
