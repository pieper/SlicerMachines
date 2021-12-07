
echo Installing to image build with:
echo SSH=${SSH}
echo SCP=${SCP}
echo SCPHOST=${SCPHOST}
echo SLICER_EXTS=${SLICER_EXTS}


#
# wait for X server
#
echo -n "waiting for X server to start"
while ! ${SSH} xset -d :0 -q &> /dev/null
do
  echo -n .
  sleep 1
done
echo

${SSH} cat \> /tmp/install.py << EOF
import json
import os
import sys
extensionName = os.environ['EXTENSION_TO_INSTALL']
em = slicer.app.extensionsManagerModel()
try:
  extensionMetaData = em.retrieveExtensionMetadataByName(extensionName)
  # for the nightly
  #url = f"{em.serverUrl().toString()}/api/v1/item/{extensionMetaData['_id']}/download"
  # for the release
  url = f"https://slicer-packages.kitware.com/api/v1/item/{extensionMetaData['item_id']}/download"
  extensionPackageFilename = slicer.app.temporaryPath+'/'+extensionMetaData['item_id']
  slicer.util.downloadFile(url, extensionPackageFilename)
  em.installExtension(extensionPackageFilename)
except:
  print(f"Could not install {extensionName}")
  print(f"Metadata is {json.dumps(extensionMetaData)}")
  print(sys.exc_info()[0])
exit()
EOF

for ext in ${SLICER_EXTS}
do
  echo "Installing ${ext}"
  ${SSH} sudo \
    DISPLAY=:0 \
    EXTENSION_TO_INSTALL=${ext} \
      Slicer --python-script /tmp/install.py
done


#
# set up window manager
#
# slicer wallpaper for ubuntu user
${SCP} resources/xfce4-desktop.xml ${SCPHOST}:xfce4-desktop.xml
${SSH} mkdir -p .config/xfce4/xfconf/xfce-perchannel-xml
${SSH} mv xfce4-desktop.xml .config/xfce4/xfconf/xfce-perchannel-xml
${SSH} sudo cp -r .config/xfce4 ~ubuntu/.config
${SSH} sudo chown -R ubuntu:ubuntu ~ubuntu/.config

${SCP} resources/slicer.desktop ${SCPHOST}:
${SSH} sudo mv slicer.desktop /usr/share/applications

${SCP} resources/3D-Slicer.svg ${SCPHOST}:
${SSH} sudo mv 3D-Slicer.svg /opt/slicer
