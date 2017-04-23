#!/bin/bash

#1. update source.list
sudo apt-get update

#2.install tightvncserver
sudo apt-get install tightvncserver

#3. run vnc server
# :1 = monitor 1
# 1024x740 for web monitor
# depth 16 is just ok 
# pixelformat rgb565
# set a password for vncserver
sudo vncserver :1 -geometry 1024x740 -depth 16 -pixelformat rgb565

#4. install vncviewer in your host
#sudo apt-get install vncviewer

#5. run vncviewer monitor 1  in your host
#vncviewer 192.168.0.3:1
