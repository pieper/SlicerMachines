
echo export SSH=${SSH}
echo export SCP=${SCP}
echo export SCPHOST=${SCPHOST}
echo export SLICER_EXTS=${SLICER_EXTS}

echo -n "waiting for X server to start"
while ! ${SSH} xset -d :0 -q &> /dev/null
do
  echo -n .
  sleep 1
done

${SSH} cat \> /tmp/install.py << EOF
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
  ${SSH} \
    DISPLAY=:0 \
    EXTENSION_TO_INSTALL=${ext} \
      Slicer --python-script /tmp/install.py
done


#
# set up window manager
#

${SCP} resources/xfce4-desktop.xml ${SCPHOST}:xfce4-desktop.xml
${SSH} mkdir -p .config/xfce4/xfconf/xfce-perchannel-xml
${SSH} mv xfce4-desktop.xml .config/xfce4/xfconf/xfce-perchannel-xml

${SCP} resources/slicer.desktop ${SCPHOST}:
${SSH} sudo mv slicer.desktop /usr/share/applications

${SCP} resources/3D-Slicer.svg ${SCPHOST}:
${SSH} sudo mv 3D-Slicer.svg /opt/slicer

