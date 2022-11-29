#!/bin/bash -eu

clear

source ~/demo-openrc-no_passwd.sh

# Color Vars
GREEN='\033[0;32m'
ORANGE='\033[;33m'
DGREY='\033[1;30m'
RED='\033[0;31m'
NC='\033[0m'

# Openstack Vars
FLAVOR="ds1G"
IMAGE=$(openstack image list | grep -Fiw "Ubuntu 20.04" | cut -f2 -d '|' | tr -d ' ')
NET_ID=$(openstack network list | grep private | cut -f2 -d '|' | tr -d ' ')
SEC_GROUP="default"
KEYPAIR="miclaveopenstack"
USER_DATA="./cloud-config"
VM_NAME="Ubuntu_20.04_VM"
  
for VM in {1..2}; do

	echo
    echo -e "${DGREY}Creating${NC} ${ORANGE}VM-${VM}${NC} ${GREEN}"${VM_NAME}${VM}"${NC}"
    INSTANCE_ID=`openstack server create --flavor $FLAVOR \
     --image $IMAGE \
     --nic net-id=$NET_ID \
     --security-group $SEC_GROUP \
     --key-name $KEYPAIR \
     $VM_NAME$VM \
     | grep -iFw id | cut -f3 -d '|' | tr -d ' '`

    FLOATING_IP=`openstack floating ip create "public" | grep -iF "floating_ip_address" | cut -f3 -d '|' | tr -d ''`
	
	openstack server add floating ip $INSTANCE_ID $FLOATING_IP
	
	until [[ "$(openstack server show ${INSTANCE_ID} | grep -Fi status | cut -f3 -d '|' | tr -d ' ')" == "ACTIVE" ]]; do
        true
    done

	echo -e "${ORANGE}VM-${VM}${NC} ${DGREY}ID:${NC}${INSTANCE_ID} ${GREEN}active.${NC}"
	echo -e "${DGREY}Floating_IP:${NC}${ORANGE}${FLOATING_IP}${NC}"
	echo
    
done

