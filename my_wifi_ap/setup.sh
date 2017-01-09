#!/bin/bash

#1. install udhcpd and hostapd
sudo apt-get update
sudo apt-get install udhcpd
sudo apt-get install hostapd

#2. copy all config to /
sudo cp TOP/* /

#3. change priviledge
sudo chmod +x iptables

#4. execute when boot up
sudo update-rc.d iptables defaults

