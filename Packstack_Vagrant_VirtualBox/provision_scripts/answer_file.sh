#!/bin/bash -eux

sudo yum install nano -y;

packstack --os-neutron-ml2-tenant-network-types=vxlan \
--os-neutron-l2-agent=openvswitch \
--os-neutron-ml2-type-drivers=vxlan,flat \
--os-neutron-ml2-mechanism-drivers=openvswitch \
--keystone-admin-passwd=openstack \
--provision-demo=n \
--cinder-volumes-create=y \
--os-heat-install=y \
--os-magnum-install=y \
--os-ceilometer-install=n \
--os-aodh-install=n \
--os-swift-storage-size=10G \
--gen-answer-file packstack-answers.txt

sudo sed -i -e 's:10.0.2.15:192.168.56.15:' packstack-answers.txt;

echo -e "CONFIG_NOVA_COMPUTE_PRIVIF=eth0\nCONFIG_NOVA_NETWORK_PUBIF=eth1\nCONFIG_NOVA_NETWORK_PRIVIF=eth0" >> packstack-answers.txt;