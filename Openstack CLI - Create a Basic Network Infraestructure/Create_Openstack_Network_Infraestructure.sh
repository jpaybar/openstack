#!/bin/bash

########################################################################################
# This simple "script" creates a basic network infrastructure on Openstack.            #
# When you run it, it adds to your project 3 networks (net1, net2 and net3)            #
# with their corresponding subnets (subnet1, subnet2, subnet3) in the ranges           #
# 192.168.1.0/24, 192.168.2.0/24, 192.168.3.0/24. To connect these subnets,            #
# 3 routers are added (R1, R2, R3) in which static routes are configured               #
# so that they can communicate. In turn, host routes are injected into the instances   #
# so that they can access to each other.                                               #
# A key pair and 3 instances (server1, server2 and server3) are also created           #
# and a floating IP is assigned to the server1. In this way you                        #
# can access to server1 and from there connect to the others.                          #
########################################################################################

# Create Networks
NETWORK_ID1=$(openstack network create net1 | grep ' id ' | awk '{print $4}')
NETWORK_ID2=$(openstack network create net2 | grep ' id ' | awk '{print $4}')
NETWORK_ID3=$(openstack network create net3 | grep ' id ' | awk '{print $4}')

# Add Routers
openstack router create R1
openstack router create R2
openstack router create R3

# Create Subnets
openstack subnet create subnet1 --network net1 --subnet-range 192.168.1.0/24 --dns-nameserver 8.8.8.8 
openstack subnet create subnet2 --network net2 --subnet-range 192.168.2.0/24 --dns-nameserver 8.8.8.8 
openstack subnet create subnet3 --network net3 --subnet-range 192.168.3.0/24 --dns-nameserver 8.8.8.8 

# Connect R1 to public network and subnet1
openstack router set R1 --external-gateway public #=== Connect R1 to "public" network as external gateway ===#
openstack router add subnet R1 subnet1 #=== Connect subnet "subnet1" to router R1 to the IP X.X.X.1 by default ===#

# Add a port to subnet1 to connect to R2 and subnet2 is assigned to this router as well
PORT_ID1=$( openstack port create --network net1 --fixed-ip subnet=subnet1,ip-address=192.168.1.254 port1 | grep ' id ' | awk '{print $4}')
openstack router add port R2 $PORT_ID1
openstack router add subnet R2 subnet2

# Add a port to subnet2 to connect to R3 and subnet3 is assigned to this router as well
PORT_ID2=$( openstack port create --network net2 --fixed-ip subnet=subnet2,ip-address=192.168.2.254 port1 | grep ' id ' | awk '{print $4}')
openstack router add port R3 $PORT_ID2
openstack router add subnet R3 subnet3

# Add routes to DHCP server of subnet1 so that it sends to instances a path to reach subnet2 and subnet3 
openstack subnet set --host-route destination=192.168.2.0/24,gateway=192.168.1.254 subnet1
openstack subnet set --host-route destination=192.168.3.0/24,gateway=192.168.1.254 subnet1

# Add routes to DHCP server of subnet2 so that it sends to instances a path to reach subnet3
openstack subnet set --host-route destination=192.168.3.0/24,gateway=192.168.2.254 subnet2


# Create SSH and ICMP connection rules and they are added to default security group
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

# Create a key pair and assign the right permissions
openstack keypair create myprivatekey > myprivatekey.pem
chmod 600 myprivatekey.pem

# Create 3 instances connected to each subnet
CIRROS_IMAGE=$(openstack image list | grep -F cirros | cut -f3 -d '|')
CIRROS_FLAVOR=$(openstack flavor list | grep -F cirros | cut -f3 -d '|')
KEYPAIR_NAME=$(openstack keypair list | grep -F myprivatekey | cut -f2 -d ' ')

openstack server create --flavor $CIRROS_FLAVOR \
 --image $CIRROS_IMAGE \
 --nic net-id=$NETWORK_ID1 \
 --security-group default \
 --key-name $KEYPAIR_NAME \
 server1		

openstack server create --flavor $CIRROS_FLAVOR \
 --image $CIRROS_IMAGE \
 --nic net-id=$NETWORK_ID2 \
 --security-group default \
 --key-name $KEYPAIR_NAME \
 server2

openstack server create --flavor $CIRROS_FLAVOR \
 --image $CIRROS_IMAGE \
 --nic net-id=$NETWORK_ID3 \
 --security-group default \
 --key-name $KEYPAIR_NAME \
 server3

# Assign a floating IP to the server1 instance
#=== To assign a Floating IP to an instance, the subnet to which the instance is connected must reach the "public" network ===#
#=== RUN THIS COMMAND: openstack router set "ROUTER" --external-gateway public ===#

IP_SERVER1=$(openstack floating ip create public | grep -F floating_ip_address | cut -f3 -d '|')
openstack server add floating ip server1 $IP_SERVER1

# Add a routing route on R2 so that it can access subnet3
openstack router add route --route destination=192.168.3.0/24,gateway=192.168.2.254 R2

# Add a routing route on R3 so that it can access subnet1
openstack router add route --route destination=192.168.1.0/24,gateway=192.168.2.1 R3

