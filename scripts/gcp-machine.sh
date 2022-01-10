#!/bin/bash

IMAGE_PROJECT=idc-sandbox-000
IMAGE_FAMILY=slicer
BILLING_PROJECT=idc-lnq-000

INSTANCE_ID=${USER}-slicermachine-$(date +%Ft%H-%I-%M)
SSH="gcloud --project ${BILLING_PROJECT} compute ssh ${INSTANCE_ID} --"


echo "Launching gcp instance ${INSTANCE_ID}"

status_start_time="$(date -u +%s)"

#
# create the instance
#

gcloud compute --project ${BILLING_PROJECT} \
  instances create ${INSTANCE_ID} \
    --image-project=${IMAGE_PROJECT} --image-family=${IMAGE_FAMILY} \
    --machine-type=n1-standard-8 --accelerator=type=nvidia-tesla-k80,count=1 \
    --boot-disk-size=200GB --boot-disk-type=pd-ssd --maintenance-policy=TERMINATE

echo Created ${INSTANCE_ID}


#
# wait for it to start
#

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

LOCAL_PORT=6080
while nc -z localhost ${LOCAL_PORT}; do LOCAL_PORT=$((LOCAL_PORT+1)); done

sleep 1 && open "http://localhost:${LOCAL_PORT}/vnc.html?autoconnect=true" &
SSH_VNC="${SSH} -L ${LOCAL_PORT}:localhost:6080"
echo Connecting with:
echo ${SSH_VNC}
${SSH_VNC}

