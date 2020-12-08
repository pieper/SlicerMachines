
echo export KEY=${KEY}
echo export IP=${IP}
echo export SLICER_EXTS=${SLICER_EXTS}

echo -n "waiting for X server to start"
while ! ssh -i ${KEY} ubuntu@${IP} xset -d :0 -q &> /dev/null
do
  echo -n .
  sleep 1
done

ssh -i ${KEY} ubuntu@${IP} cat \> /tmp/install.py << EOF
import os
extensionName = os.environ['EXTENSION_TO_INSTALL']
print(f"installing {extensionName}")
emm = slicer.app.extensionsManagerModel()
extensionMetaData = emm.retrieveExtensionMetadataByName(extensionName)
url = emm.serverUrl().toString()+'/download/item/'+extensionMetaData['item_id']
extensionPackageFilename = slicer.app.temporaryPath+'/'+extensionMetaData['md5']
slicer.util.downloadFile(url, extensionPackageFilename)
emm.installExtension(extensionPackageFilename)
exit()
EOF


for ext in ${SLICER_EXTS}
do
  echo "Installing ${ext}"
  ssh -i ${KEY} ubuntu@${IP} \
    DISPLAY=:0 \
    EXTENSION_TO_INSTALL=${ext} \
      Slicer --python-script /tmp/install.py
done


#
# set up window manager
#

scp -i ${KEY} resources/xfce4-desktop.xml ubuntu@${IP}:/home/ubuntu/xfce4-desktop.xml
ssh -i ${KEY} ubuntu@${IP} mkdir -p .config/xfce4/xfconf/xfce-perchannel-xml
ssh -i ${KEY} ubuntu@${IP} mv xfce4-desktop.xml .config/xfce4/xfconf/xfce-perchannel-xml
scp -i ${KEY} resources/slicer.desktop ubuntu@${IP}:/home/ubuntu
ssh -i ${KEY} ubuntu@${IP} sudo mv slicer.desktop /usr/share/applications
scp -i ${KEY} resources/3D-Slicer.svg ubuntu@${IP}:/home/ubuntu
ssh -i ${KEY} ubuntu@${IP} sudo mv 3D-Slicer.svg /opt/slicer

