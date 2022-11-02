#!/bin/bash -eux

# Create External Public Network
openstack network create  --external \
  --provider-physical-network extnet \
  --provider-network-type flat extnet

# Create External Public Subnet  
openstack subnet create --network extnet \
  --allocation-pool start=192.168.56.226,end=192.168.56.254 \
  --dns-nameserver 1.1.1.1 --gateway 192.168.56.1 \
  --subnet-range 192.168.56.0/24 extnet-subnet
  
# Create Private Network
openstack network create private

# Create Private Subnet
openstack subnet create --network private --subnet-range 10.0.0.0/24 private-subnet

# Create a Router
openstack router create router1

# Set up Gateway External Public Network for Router1
openstack router set router1 --external-gateway extnet

# Add Private Subnet Interface to Router1
openstack router add subnet router1 private-subnet

# Create a Keypair and assigning right permissions
openstack keypair create mykeypair > mykeypair.pem
chmod 600 mykeypair.pem

# Create SSH and ICMP security rule for security group "default"
SEC_GROUP=`openstack security group list --project admin | grep default | cut -f2 -d '|' | tr -d ' '`
openstack security group rule create --proto icmp $SEC_GROUP
openstack security group rule create --proto tcp --dst-port 22 $SEC_GROUP

# Download Ubuntu 18.04 image
if which wget >/dev/null ; then
	echo "Downloading Ubuntu image via wget."
	wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
elif which curl >/dev/null ; then
	echo "Downloading Ubuntu image via curl."
	curl https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img -o bionic-server-cloudimg-amd64.img
else
	echo "Cannot download image, neither wget nor curl is available."
fi

# Create image on Openstack
openstack image create --public --container-format=bare --disk-format=qcow2 \
  --file bionic-server-cloudimg-amd64.img "Ubuntu_18.04"
 
# Create our own flavor
openstack flavor create MY.tiny --id 1a \
  --ram 1024 --disk 5 --vcpus 1
  
# Create an Instance
INSTANCE=`openstack server create --flavor MY.tiny \
  --image $(openstack image list | grep -Fi ubuntu | cut -f3 -d '|') \
  --nic net-id=$(openstack network list | grep private | cut -f2 -d '|' | tr -d ' ') \
  --security-group $(openstack security group list --project admin | grep default | cut -f2 -d '|' | tr -d ' ') \
  --key-name $(openstack keypair list | grep -iF mykeypair | cut -f2 -d '|') Ubuntu_18.04_VM \
  | grep -iFw id | cut -f3 -d '|' | tr -d ' '`
  
# Create a Floating IP
FLOATING_IP=`openstack floating ip create extnet | grep -iF floating_ip_address | cut -f3 -d '|' | tr -d ' '`

# Assign the floating IP to our instance
openstack server add floating ip $INSTANCE $FLOATING_IP

