#!/bin/bash

# For Ubuntu 20.04

echo "#####################"
echo "Running installs"
echo "#####################"

apt-get -qq -y update
apt-get -qq -y upgrade

apt-get install -qq -y awscli

apt-get -qq -y update
apt-get install -qq -y ubuntu-drivers-common
ubuntu-drivers install
apt-get install -qq -y xinit
apt-get install -qq -y x11vnc
apt-get install -qq -y xterm
apt-get install -qq -y libpulse-dev libnss3 libglu1-mesa
apt-get install --reinstall libxcb-xinerama0
apt-get install -qq -y python

nvidia-xconfig

apt-get -qq -y remove gdm3
apt-get -qq -y install xfce4

# somehow default browser is not available by default
apt-get -qq -y install firefox

# install gcsfuse, just in case
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get -qq update
sudo apt-get -qq -y install gcsfuse

# turn off display manager
systemctl set-default multi-user.target

echo "#####################"
echo "Finished running installs"
echo "#####################"
