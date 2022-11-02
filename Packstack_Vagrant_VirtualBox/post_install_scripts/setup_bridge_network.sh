#!/bin/bash -eux

sudo -- bash -c 'cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-ex
DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=192.168.56.15
NETMASK=255.255.255.0
GATEWAY=192.168.56.1
DNS1=8.8.8.8
DNS2=1.1.1.1
ONBOOT=yes
EOF'

sudo -- bash -c 'echo -e "TYPE=OVSPort\nDEVICETYPE=ovs\nOVS_BRIDGE=br-ex" >> /etc/sysconfig/network-scripts/ifcfg-eth1'

sudo yum install openstack-utils -y

if [ -d /etc/neutron/plugins/openvswitch ] ; then
	echo "openvswitch directory already exists."
else
	echo "Setting up ovs_neutron_plugin.ini."
	sudo mkdir /etc/neutron/plugins/openvswitch
	sudo openstack-config --set /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
		ovs bridge_mappings extnet:br-ex
fi
 
sudo systemctl restart network
sudo systemctl restart neutron-openvswitch-agent
sudo systemctl restart neutron-server