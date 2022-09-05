# Openstack CLI - Create a Basic Network Infraestructure

### 

### Description:

In this proof of concept we are going to create a basic network infrastructure on top of `Openstack`. We will create 3 networks (`net1`, `net2` and `net3`) with their corresponding subnets (`subnet1` 192.168.1.0/24, `subnet2` 192.168.1.0/24 and `subnet3` 192.168.1.0/24) and 3 routers (`R1`, `R2` and `R3`) to interconnect them. We will also create static routes in routers `R1` and `R2` so that they can access the different subnets and host routes on DHCP servers of each subnet so that the instances that we create can communicate with each other.
3 instances will be created (`server1`, `server2` and `server3`) one in each subnet with `"cirros"` image and a pair of keys will also be generated to inject them into the instances (although it is not necessary since said image has a username and password by default `"cirros /gocubsgo"`).
We will assign a floating IP to the `server1` instance, which we can access externally and from there connect to the others.

##### Initial Openstack Network Structure

![Topologia_red_default.PNG](https://github.com/jpaybar/OpenStack/blob/main/Openstack%20CLI%20-%20Create%20a%20Basic%20Network%20Infraestructure/images/Topologia_red_default.PNG)

##### Create Networks

```bash
openstack subnet create subnet1 --network net1 --subnet-range 192.168.1.0/24 --dns-nameserver 8.8.8.8 
openstack subnet create subnet2 --network net2 --subnet-range 192.168.2.0/24 --dns-nameserver 8.8.8.8 
openstack subnet create subnet3 --network net3 --subnet-range 192.168.3.0/24 --dns-nameserver 8.8.8.8
```

##### Add Routers

```bash
openstack router create R1
openstack router create R2
openstack router create R3
```

##### Create Subnets

```bash
openstack subnet create subnet1 --network net1 --subnet-range 192.168.1.0/24 --dns-nameserver 8.8.8.8 
openstack subnet create subnet2 --network net2 --subnet-range 192.168.2.0/24 --dns-nameserver 8.8.8.8 
openstack subnet create subnet3 --network net3 --subnet-range 192.168.3.0/24 --dns-nameserver 8.8.8.8 
```

##### Connect R1 to "public" network and subnet1

```bash
openstack router set R1 --external-gateway public 
openstack router add subnet R1 subnet1 
```

##### Add a port to subnet1 to connect to R2 and subnet2 is assigned to this router as well

```bash
PORT_ID1=$( openstack port create --network net1 --fixed-ip subnet=subnet1,ip-address=192.168.1.254 port1 | grep ' id ' | awk '{print $4}')
openstack router add port R2 $PORT_ID1
openstack router add subnet R2 subnet2
```

##### Add a port to subnet2 to connect to R3 and subnet3 is assigned to this router as well

```bash
PORT_ID2=$( openstack port create --network net2 --fixed-ip subnet=subnet2,ip-address=192.168.2.254 port1 | grep ' id ' | awk '{print $4}')
openstack router add port R3 $PORT_ID2
openstack router add subnet R3 subnet3
```

##### Add routes to DHCP server of subnet1 so that it sends to instances a path to reach subnet2 and subnet3

```bash
openstack subnet set --host-route destination=192.168.2.0/24,gateway=192.168.1.254 subnet1
openstack subnet set --host-route destination=192.168.3.0/24,gateway=192.168.1.254 subnet1
```

##### Add routes to DHCP server of subnet2 so that it sends to instances a path to reach subnet3

```bash
openstack subnet set --host-route destination=192.168.3.0/24,gateway=192.168.2.254 subnet2
```

##### Create SSH and ICMP connection rules and they are added to default security group

```bash
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
```

##### Create a key pair and assign the right permissions

In this case it is not necessary to use a "keypair" since the cirros image comes with username and passwords (cirros/gocubsgo).

```bash
openstack keypair create myprivatekey > myprivatekey.pem
chmod 600 myprivatekey.pem
```

##### Create 3 instances connected to each subnet

```bash
CIRROS_IMAGE=$(openstack image list | grep -F cirros | cut -f3 -d '|')
CIRROS_FLAVOR=$(openstack flavor list | grep -F cirros | cut -f3 -d '|')
KEYPAIR_NAME=$(openstack keypair list | grep -F myprivatekey | cut -f2 -d ' ')
```

```bash
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
```

##### Assign a floating IP to the server1 instance

To assign a Floating IP to an instance, the subnet to which the instance is connected must reach the "public" network. So we can access externally to server1 and from there connect to the others.

```bash
IP_SERVER1=$(openstack floating ip create public | grep -F floating_ip_address | cut -f3 -d '|')
openstack server add floating ip server1 $IP_SERVER1
```

##### Add a routing route on R2 so that it can access subnet3

```bash
openstack router add route --route destination=192.168.3.0/24,gateway=192.168.2.254 R2
```

##### Add a routing route on R3 so that it can access subnet1

```bash
openstack router add route --route destination=192.168.1.0/24,gateway=192.168.2.1 R3
```

##### Final Openstack Network Structure

![Topologia_red.PNG](https://github.com/jpaybar/OpenStack/blob/main/Openstack%20CLI%20-%20Create%20a%20Basic%20Network%20Infraestructure/images/Topologia_red.PNG)

### Testing the environment

Connecting to the Floating IP on `server1` instance and doing ping to the others:

![Connection_server1_ping_others.PNG](https://github.com/jpaybar/OpenStack/blob/main/Openstack%20CLI%20-%20Create%20a%20Basic%20Network%20Infraestructure/images/Connection_server1_ping_others.PNG)

SSH connection:

![ssh_connection.PNG](https://github.com/jpaybar/OpenStack/blob/main/Openstack%20CLI%20-%20Create%20a%20Basic%20Network%20Infraestructure/images/ssh_connection.PNG)

To create the network infrastructure in an easier way, we can run this simple script that will create all the objects automatically.

[Create_Openstack_Network_Infraestructure.sh](https://github.com/jpaybar/OpenStack/blob/main/Openstack%20CLI%20-%20Create%20a%20Basic%20Network%20Infraestructure/Create_Openstack_Network_Infraestructure.sh)



### HOW TO CREATE AN INITIAL BASIC NETWORK INFRASTRUCTURE (PUBLIC/PRIVATE NETWORK)

The `--provider-physical-network "provider"` and `--provider-network-type "flat"` options connect the flat virtual 
network to the flat (native/untagged) physical network on the eth1 interface on the host using information 
from the following files on `"/etc/neutron/plugins/ml2/"`:

`ml2_conf.ini`
```bash
[ml2_type_flat]
flat_networks = provider
```

`linuxbridge_agent.ini`
```bash
[linux_bridge]
physical_interface_mappings = provider:eth1
```

### DELETE `public` NETWORK

```bash
source admin_openrc.sh
openstack network delete public
```

### CREATE `public` NETWORK AND SUBNETWORK

```bash
openstack network create  --external \
  --provider-physical-network public \
  --provider-network-type flat public
```
```bash
openstack subnet create --network public \
  --allocation-pool start=192.168.56.226,end=192.168.56.254 \
  --dns-nameserver 1.1.1.1 --gateway 192.168.56.225 \
  --subnet-range 192.168.56.224/27 public-subnet
```

### CREATE `private` NETWORK AND SUBNETWORK FOR PROJECT `demo`

```bash
source demo_openrc.sh
openstack network create private
openstack subnet create --network private --subnet-range 10.0.0.0/26 private-subnet
```

### CREATE A ROUTER CALLED `Router1` 
We create the router "router1" and set the gateway to the "public" network, then add the subnet "private-subnet" to that router.

```bash
openstack router create router1
openstack router set router1 --external-gateway public
openstack router add subnet router1 private-subnet
```

Author Information
------------------

Juan Manuel Payán Barea    (IT Technician)   [st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com)

[jpaybar (Juan M. Payán Barea) · GitHub](https://github.com/jpaybar)

https://es.linkedin.com/in/juanmanuelpayan
