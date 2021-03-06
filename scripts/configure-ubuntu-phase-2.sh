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


# run mwm
apt-get install -q -y mwm
cat << EOF > /etc/systemd/system/mwm.service
[Unit]
Description="mwm"
After=slicerX.service

[Service]
ExecStart=/usr/bin/mwm -d :0
User=ubuntu
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable mwm

# run xfce4-session - not currently working with vnc due to display manager issue
cat << EOF > /etc/systemd/system/xfce4-session.service
[Unit]
Description="xfce4"
After=slicerX.service

[Service]
ExecStart=/usr/bin/xfce4-session --display :0
User=ubuntu
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl disable xfce4-session

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
# systemctl enable resize-screen

# install Slicer
mkdir /opt/slicer
cd /opt/slicer
wget --quiet "https://download.slicer.org/bitstream/1341035" -O Slicer-4.11.20200930-linux-amd64.tar.gz
tar xfz Slicer-4.11.20200930-linux-amd64.tar.gz
ln -s /opt/slicer/Slicer-4.11.20200930-linux-amd64/Slicer /usr/local/bin/Slicer
ln -s /opt/slicer/Slicer-4.11.20200930-linux-amd64/Slicer /usr/local/bin/slicer

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

