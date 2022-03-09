#!/bin/bash

# For Ubuntu 20.04

echo "#####################"
echo "Running installs"
echo "#####################"

apt-get -q -y update
apt-get -q -y upgrade

apt-get install -q -y awscli

apt-get -q -y update
apt-get install -q -y ubuntu-drivers-common
ubuntu-drivers install
apt-get install -q -y xinit
apt-get install -q -y x11vnc
apt-get install -q -y xterm
apt-get install -q -y libpulse-dev libnss3 libglu1-mesa
apt-get install --reinstall libxcb-xinerama0
apt-get install -q -y python

nvidia-xconfig

apt-get -q -y remove gdm3
apt-get -q -y install xfce4

# somehow default browser is not available by default
apt-get -q -y install firefox

# install gcsfuse, just in case
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get -q -y install gcsfuse

# turn off display manager
systemctl set-default multi-user.target

echo "#####################"
echo "Finished running installs"
echo "#####################"
