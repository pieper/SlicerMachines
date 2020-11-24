# For Ubuntu 20.04


sudo apt -y update
sudo apt -y upgrade

sudo apt install -y awscli

sudo apt-get -y update && \
  sudo apt install -y ubuntu-drivers-common && \
  sudo ubuntu-drivers autoinstall && \
  sudo apt install -y xinit && \
  sudo apt-get install -y x11vnc && \
  sudo apt-get install -y xterm && \
  sudo apt-get install -y libpulse-dev libnss3 libglu1-mesa && \
  sudo apt-get install --reinstall libxcb-xinerama0 && \
  sudo apt-get install -y python 
  
sudo nvidia-xconfig

# TODO: requires need to get rid of display manager
# sudo apt-get -y install xfce4

wget "https://download.slicer.org/bitstream/1341035" -O Slicer-4.11-20200930.tar.gz
tar xfz Slicer-4.11-20200930.tar.gz 
