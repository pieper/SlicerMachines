#!/bin/bash

# For Ubuntu 20.04


apt -y update
apt -y upgrade

apt install -y awscli

apt -y update
apt install -y ubuntu-drivers-common
ubuntu-drivers autoinstall
apt install -y xinit
apt install -y x11vnc
apt install -y xterm
apt install -y libpulse-dev libnss3 libglu1-mesa
apt install --reinstall libxcb-xinerama0
apt install -y python 
  
nvidia-xconfig

apt -y remove gdm3
apt -y install xfce4


# turn of display manager
systemctl set-default multi-user.target


# configure X to use the GPU
GPU_BUS_ID=$(nvidia-xconfig --query-gpu-info | grep PCI | awk 'NF{ print $NF }')
cp /etc/X11/xorg.conf /etc/X11/xorg.conf.no-gpu
sed -i "/.*NVIDIA Corporation.*/a\ \ \ \ BusID          \"${GPU_BUS_ID}\""  /etc/X11/xorg.conf


# install slicerX
cat << EOF > /etc/X11/Xwrapper.config 
allowed_users = anybody
EOF
cat << EOF > /etc/systemd/system/slicerX.service 
[Unit]
Description = run an x server for slicer
After=syslog.target network.target

[Service]
Type=simple
User=ubuntu
ExecStart = /usr/bin/xinit -- +extension GLX

[Install]
WantedBy=multi-user.target
EOF
systemctl enable slicerX


# install x11vnc
cat << EOF > /etc/systemd/system/x11vnc.service 
[Unit]
Description="x11vnc"
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/x11vnc -forever -display :0
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable x11vnc


# install noVNC
mkdir /opt/novnc
(cd /opt/novnc; git clone https://github.com/novnc/noVNC)
(cd /opt/novnc/noVNC; git checkout v1.2.0)
(cd /opt/novnc/noVNC/utils; git clone https://github.com/novnc/websockify)
(cd /opt/novnc/noVNC/utils/websockify; git checkout v0.9.0)

cat << EOF > /etc/systemd/system/novnc.service 
[Unit]
Description = start noVNC service
After=syslog.target network.target

[Service]
Type=simple
User=ubuntu
ExecStart = /opt/novnc/noVNC/utils/launch.sh 

[Install]
WantedBy=multi-user.target
EOF
systemctl enable novnc


# run xfce4 session
# - this is unstable for some reason - don't run it via systemd
cat << EOF > /etc/systemd/system/xfce4-session.service 
[Unit]
Description="xfce4 session"
After=slicerX.service

[Service]
ExecStart=/usr/bin/xfce4-session --display :0
User=ubuntu
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
# systemctl enable xfce4-session


# install Slicer
mkdir /opt/slicer
cd /opt/slicer
wget "https://download.slicer.org/bitstream/1341035" -O Slicer-4.11.20200930-linux-amd64.tar.gz
tar xfz Slicer-4.11.20200930-linux-amd64.tar.gz
ln -s /opt/slicer/Slicer-4.11.20200930-linux-amd64/Slicer /usr/local/bin/Slicer

# run slicer
cat << EOF > /etc/systemd/system/slicer.service 
[Unit]
Description="slicer session"
After=slicerX.service

[Service]
Environment=DISPLAY=:0
User=ubuntu
ExecStart=/usr/local/bin/Slicer
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF
systemctl enable slicer


# turn on slicer environment
systemctl isolate multi-user.target

