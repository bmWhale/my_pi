#!/bin/bash

# 1. update repo
sudo apt-get update
sudo apt-get upgrade

# 2. download and install ffmpeg package
wget https://github.com/ccrisan/motioneye/wiki/precompiled/ffmpeg_3.1.1-1_armhf.deb
sudo dpkg -i ffmpeg_3.1.1-1_armhf.deb

# 3. install some packages
sudo apt-get install curl libssl-dev libcurl4-openssl-dev libjpeg-dev libx264-142 libavcodec56 libavformat56 libmysqlclient18 libswscale3 libpq5

# 4. download and install motion
wget https://github.com/Motion-Project/motion/releases/download/release-4.0.1/pi_jessie_motion_4.0.1-1_armhf.deb
sudo dpkg -i pi_jessie_motion_4.0.1-1_armhf.deb

# 5. replace /etc/motion/motion.conf
sudo cp -i motion.conf /etc/motion/

# 6. replace /etc/default/motion
sudo cp -i motion /etc/default/

# 7. start motion
sudo service motion restart

# 8. done 

