#!/bin/bash

set -e

#1. install squid
sudo apt install squid

#2. backup squid.conf

if [ ! -f  /etc/squid/squid.conf.originals ];then
	sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.original
	sudo chmod a-w /etc/squid/squid.conf.original
fi

#3. copy /etc/squid/squid.conf
	sudo cp -rfi etc/squid/* /etc/squid/

#4 restart service
	sudo systemctl restart squid.service
	sudo systemctl enable squid.service


