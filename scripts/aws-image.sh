#!/bin/bash

KEY_NAME=condatest
KEY=~/.ssh/${KEY_NAME}.pem

UBUNTU_2004_IMAGE_ID=ami-0885b1f6bd170450c
SLICER_EXTS="Auto3dgm SegmentEditorExtraEffects Sandbox SlicerIGT RawImageGuess SlicerDcm2nii SurfaceWrapSolidify SlicerMorph"

BUILD_DATE=$(date -u "+%Y-%0m-%0d-%0H.%0M.%0S")

echo "Creating new Slicer image based on ${UBUNTU_2004_IMAGE_ID}"


#
# create the instance
#

INSTANCE_ID=$( \
  aws ec2 run-instances \
    --image-id ${UBUNTU_2004_IMAGE_ID} \
    --count 1 \
    --instance-type g3.4xlarge \
    --key-name condatest \
    --security-group-ids sg-06c97de13d2908d9c \
    --subnet-id subnet-09b413c8209761938 \
    --associate-public-ip-address \
  | jq -r ".Instances[0].InstanceId")

INSTANCE_NAME=SlicerMachine-${BUILD_DATE}
aws ec2 create-tags \
  --resources ${INSTANCE_ID} \
  --tags Key=Name,Value=${INSTANCE_NAME}

echo Started ${INSTANCE_ID}


#
# wait for it to start
#

status_start_time="$(date -u +%s)"

echo -n waiting for instance to start
while [ $(aws ec2 describe-instance-status --instance-ids ${INSTANCE_ID} | jq -r ".InstanceStatuses[0].SystemStatus.Status") != "ok" ]
do
  echo -n .
  sleep 1
done


status_end_time="$(date -u +%s)"

status_elapsed="$(($status_end_time-$status_start_time))"
echo "Instance started in $status_elapsed seconds"


#
# get the ip address
#

IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} | jq -r ".Reservations[0].Instances[0].PublicIpAddress")


#
# run the configure script
#

configure_start_time="$(date -u +%s)"

# turn off host checking so that host key will be automatically recorded (no prompt)
ssh -o StrictHostKeyChecking=no -i ${KEY} ubuntu@${IP} echo login works

scp -i ${KEY} scripts/configure-ubuntu.sh ubuntu@${IP}:/home/ubuntu/configure-ubuntu.sh
ssh -i ${KEY} ubuntu@${IP} sudo /home/ubuntu/configure-ubuntu.sh

( export KEY=${KEY} \
         IP=${IP} \
         SLICER_EXTS=${SLICER_EXTS} ;\
  ./scripts/configure-slicer.sh
)

scp -i ${KEY} resources/.xscreensaver ubuntu@${IP}:/home/ubuntu/.xscreensaver

configure_end_time="$(date -u +%s)"
configure_elapsed="$(($configure_end_time-$configure_start_time))"
echo "Instance configured in $configure_elapsed seconds"


#
# make the machine image
#

make_image_start_time="$(date -u +%s)"

SLICER_IMAGE_ID=$( \
  aws ec2 create-image \
    --description "Slicer desktop with nvidia driver" \
    --name "SlicerMachine"-${BUILD_DATE} \
    --instance-id ${INSTANCE_ID} \
    | jq -r ".ImageId")

SLICER_IMAGE_NAME=SlicerMachineImage-${BUILD_DATE}
aws ec2 create-tags \
  --resources ${SLICER_IMAGE_ID} \
  --tags Key=Name,Value=${SLICER_IMAGE_NAME}
echo Created ${SLICER_IMAGE_ID} from ${INSTANCE_ID} as ${SLICER_IMAGE_NAME}

echo -n waiting for image to build
while [ $(aws ec2 describe-images --image-ids ${SLICER_IMAGE_ID} | jq -r ".Images[0].State") != "available" ]
do
  echo -n .
  sleep 1
done

make_image_end_time="$(date -u +%s)"
make_image_elapsed="$(($make_image_end_time-$make_image_start_time))"
echo "Instance image made in $make_image_elapsed seconds"


echo "--------------------------------------------------------------------------------"
echo "Image Complete"
echo "Instance started in ${status_elapsed} seconds"
echo "Instance configured in ${configure_elapsed} seconds"
echo "Instance image started in ${make_image_elapsed} seconds"
echo
echo "Connect with:"
echo ssh -i ${KEY} ubuntu@${IP} -L 5432:localhost:6080
echo http://localhost:5432/vnc.html
