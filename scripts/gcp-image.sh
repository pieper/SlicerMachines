#!/bin/bash

# SLICER_EXTS="MarkupsToModel Auto3dgm SegmentEditorExtraEffects Sandbox SlicerIGT RawImageGuess SlicerDcm2nii SurfaceWrapSolidify SlicerMorph"
SLICER_EXTS=""

INSTANCE_ID=slicermachine-$(date +%Ft%H-%I-%M)
SSH="gcloud compute ssh ${INSTANCE_ID} --"
SCP="gcloud compute scp"
SCPHOST=${INSTANCE_ID}

echo "Creating new Slicer gcp image ${INSTANCE_ID}"

#
# create the instance
#

gcloud compute instances create \
  ${INSTANCE_ID} \
  --image-project ubuntu-os-cloud \
  --image-family ubuntu-2004-lts \
  --machine-type n1-standard-8 \
  --boot-disk-size 200GB \
  --boot-disk-type pd-ssd \
  --accelerator=type=nvidia-tesla-k80,count=1 \
  --maintenance-policy TERMINATE

echo Created ${INSTANCE_ID}


#
# wait for it to start
#

status_start_time="$(date -u +%s)"

echo -n waiting for instance to start
while ! ${SSH} -o ConnectTimeout=1 echo ready &> /dev/null
do
  echo -n .
  sleep 1
done
echo

status_end_time="$(date -u +%s)"
status_elapsed="$(($status_end_time-$status_start_time))"
echo "Instance started in $status_elapsed seconds"


#
# run the configure script
#

configure_start_time="$(date -u +%s)"

# run the first round of installs
${SCP} scripts/configure-ubuntu-phase-1.sh ${SCPHOST}:configure-ubuntu-phase-1.sh
${SSH} sudo /bin/bash ./configure-ubuntu-phase-1.sh

# reboot the instance so nvidia driver sees GPU
${SSH} sudo reboot
echo "waiting for reboot"
while ! ${SSH} -o ConnectTimeout=1 echo ready &> /dev/null
do
  echo -n .
  sleep 1
done

# run second round of installs
${SCP} scripts/configure-ubuntu-phase-2.sh ${SCPHOST}:configure-ubuntu-phase-2.sh
${SSH} sudo /bin/bash ./configure-ubuntu-phase-2.sh

( export SSH=${SSH} \
         SCP=${SCP} \
         SCPHOST=${SCPHOST} \
         SLICER_EXTS=${SLICER_EXTS} ;\
  ./scripts/configure-slicer.sh
)

${SCP} resources/.xscreensaver ${SCPHOST}:.xscreensaver

configure_end_time="$(date -u +%s)"
configure_elapsed="$(($configure_end_time-$configure_start_time))"
echo "Instance configured in $configure_elapsed seconds"

#
# make the machine image
#

make_image_start_time="$(date -u +%s)"

gcloud compute instances stop ${INSTANCE_ID}

gcloud compute images create ${INSTANCE_ID} \
  --source-disk=${INSTANCE_ID} \
  --family=slicer \
  --storage-location=us

echo -n waiting for image to build
while [ $(gcloud compute images describe --format json ${INSTANCE_ID} | jq -r ".status") == "PENDING" ]
do
  echo -n .
  sleep 1
done
echo ...done


make_image_end_time="$(date -u +%s)"
make_image_elapsed="$(($make_image_end_time-$make_image_start_time))"
echo "Instance image made in $make_image_elapsed seconds"

echo deleting compute instance ${INSTANCE_ID}
gcloud compute instances stop ${INSTANCE_ID}

echo "--------------------------------------------------------------------------------"
echo "Image Complete"
echo "Instance started in ${status_elapsed} seconds"
echo "Instance configured in ${configure_elapsed} seconds"
echo "Instance image started in ${make_image_elapsed} seconds"
echo
echo Image name is: ${INSTANCE_ID}


echo test with:
echo gcloud compute instances create slicer-machine --machine-type=n1-standard-8 --accelerator=type=nvidia-tesla-k80,count=1 --image=${INSTANCE_ID} --image-project=idc-sandbox-000 --boot-disk-size=200GB --boot-disk-type=pd-balanced --maintenance-policy=TERMINATE

echo connect with:
echo gcloud compute ssh slicer-machine -- -L 6080:localhost:6080

