#!/bin/bash

KEY_NAME=condatest
KEY=~/.ssh/${KEY_NAME}.pem

INSTANCE_TYPE=g5.4xlarge

BUILD_DATE=$(date +%Ft%H-%I-%M)
INSTANCE_ID=${USER}-slicermachine-$(date +%Ft%H-%M-%S)

# get most recent image
IMAGE_ID=$( \
  aws ec2 describe-images \
    --owners self \
  | jq -r '.Images[] |{CreationDate,ImageId} | join(" ")' \
  | sort | tail -1 | cut -d " " -f2)

echo "Creating new machine based on ${IMAGE_ID}"

status_start_time="$(date -u +%s)"

#
# create the instance
#

INSTANCE_ID=$( \
  aws ec2 run-instances \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --instance-type ${INSTANCE_TYPE} \
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

echo -n waiting for status ok
while [ $(aws ec2 describe-instance-status --instance-ids ${INSTANCE_ID} | jq -r ".InstanceStatuses[0].SystemStatus.Status") != "ok" ]
do
  echo -n .
  sleep 1
done

status_end_time="$(date -u +%s)"

status_elapsed="$(($status_end_time-$status_start_time))"
echo "Instance started in $status_elapsed seconds"

#
# get the ip address and confirm boot
#

IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} | jq -r ".Reservations[0].Instances[0].PublicIpAddress")

SSH="ssh -i ${KEY} ubuntu@${IP}"

echo "waiting for boot"
while ! ${SSH} -o ConnectTimeout=1 -o StrictHostKeyChecking=no echo ready &> /dev/null
do
  echo -n .
  sleep 1
done

# set up disks
${SSH} sudo mkdir /mnt/extra
${SSH} sudo mkfs /dev/nvme1n1
${SSH} sudo mount /dev/nvme1n1 /mnt/extra
${SSH} sudo fallocate -l 90G /mnt/extra/swapfile
${SSH} sudo chmod 600 /mnt/extra/swapfile
${SSH} sudo mkswap /mnt/extra/swapfile
${SSH} sudo swapon /mnt/extra/swapfile

# find free port
LOCAL_PORT=6080
while nc -z localhost ${LOCAL_PORT}; do LOCAL_PORT=$((LOCAL_PORT+1)); done

sleep 1 && open "http://localhost:${LOCAL_PORT}/vnc.html?autoconnect=true" &
SSH_VNC="${SSH} -L ${LOCAL_PORT}:localhost:6080"
echo Connecting with:
echo ${SSH_VNC}
${SSH_VNC}
