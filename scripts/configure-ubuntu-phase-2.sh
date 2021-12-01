#!/bin/bash

# configure X to use the GPU
GPU_BUS_ID=$(nvidia-xconfig --query-gpu-info | grep PCI | awk 'NF{ print $NF }')
cp /etc/X11/xorg.conf /etc/X11/xorg.conf.no-gpu
sed -i "/.*NVIDIA Corporation.*/a\ \ \ \ BusID          \"${GPU_BUS_ID}\""  /etc/X11/xorg.conf
sed -i "/.* Depth .*/a\ \ \ \ \ \ \ \ Modes      \"1900x1200\""  /etc/X11/xorg.conf
sed -i "/.* Modes .*/a\ \ \ \ \ \ \ \ Virtual     2560 1600"  /etc/X11/xorg.conf

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
After=slicerX.service

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


# start window manager when X starts
cat << EOF > /home/ubuntu/.xinitrc
/usr/bin/xfce4-session
Slicer
EOF
chown ubuntu:ubuntu /home/ubuntu/.xinitrc
chmod 644 /home/ubuntu/.xinitrc


# resize screen
cat << EOF > /etc/systemd/system/resize-screen.service
[Unit]
Description="Resize screen"
After=slicerX.service

[Service]
Environment=DISPLAY=:0
User=ubuntu
ExecStart=/usr/bin/xrandr --output DVI-D-0 --mode 1920x1440
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF
systemctl enable resize-screen

# install Slicer
mkdir /opt/slicer
cd /opt/slicer
wget --quiet "https://download.slicer.org/bitstream/1341035" -O Slicer-4.11.20200930-linux-amd64.tar.gz
tar xfz Slicer-4.11.20200930-linux-amd64.tar.gz
ln -s /opt/slicer/Slicer-4.11.20200930-linux-amd64/Slicer /usr/local/bin/Slicer
ln -s /opt/slicer/Slicer-4.11.20200930-linux-amd64/Slicer /usr/local/bin/slicer


# turn on slicer environment
systemctl isolate multi-user.target

