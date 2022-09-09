# Devstack - Vagrant - Ansible on Ubuntu 20.04

###### By Juan Manuel Payán / jpaybar

st4rt.fr0m.scr4tch@gmail.com

This Vagrantfile boots an Ubuntu 20.04 virtual machine and prepares the environment for Devstack installation using an Ansible playbook running as a local provisioner.

The Vagrant box starts a virtual machine that uses VirtualBox as a provider. The machine must be partitioned with LVM volumes and not "traditional" partitioning.

You can download the Ubuntu 20.04 image .box file with LVM partition from here:
https://drive.google.com/file/d/1zcNJeX3MdkWUMYY8UwDHwbNvoiFBcGwd/view?usp=sharing

Add this box locally running:
```bash
vagrant box add openstack_victoria_ubuntu2004_presetup /path/to/file/openstack_victoria_ubuntu2004_presetup.box
```

##### Environment:

- Host, Windows 10 (20H2 version) x64, Intel(R) Core(TM) i5 3.10GHz, 16GB RAM, 256GB SSD Disk

- VirtualBox 6.1.28 

- Vagrant 2.2.19

- Ansible 2.12.6 (Installed by Vagrant as local provisioner)

- VM Ubuntu 20.04 Focal Fossa LTS (Logical Volume Partitioning), 4 CPUs, 8 GB RAM, 1 Ethernet (192.168.56.15)

- Devstack stable/Victoria version

##### Quick start:

Clone the repository

```bash
git clone https://github.com/jpaybar/OpenStack.git
```

```bash
cd OpenStack/Desvstack_Vagrant_Ansible/
```

```bash
vagrant up
```

Once the virtual machine has booted, log in via ssh:

```bash
vagrant ssh
```

Change to the user "stack"

```bash
sudo su -l stack
```

```bash
cd devstack
```

Start Devstack setup:

```bash
./stack.sh
```

When the installation finishes, we will see something similar to this screen:

![Devstack_setup_OK.PNG](https://github.com/jpaybar/OpenStack/blob/main/Desvstack_Vagrant_Ansible/Devstack_setup_OK.PNG)

The Horizon login window will be accessible through http://localhost:8888

![Horizon_screen.PNG](https://github.com/jpaybar/OpenStack/blob/main/Desvstack_Vagrant_Ansible/Horizon_screen.PNG)

User/passwd    "demo/openstack" or "admin/openstack"

##### Launch an instance through the Openstack CLI

Run next command (depending on the project and the role with which you are going to work `demo` or `admin`)

```bash
source admin-openrc.sh
```
```bash
source demo-openrc.sh
```

Create a keypair

```bash
openstack keypair create miclaveopenstack > miclaveopenstack.pem
```

Add basic ICMP and SSH rules to "default" security group 

```bash
openstack security group rule create --proto icmp default
```

```bas
openstack security group rule create --proto tcp --dst-port 22 default
```

List the available images, we only have the test "cirros"

```bash
openstack image list
```

```bash
+--------------------------------------+--------------------------+--------+
| ID                                   | Name                     | Status |
+--------------------------------------+--------------------------+--------+
| bea36c5c-3eea-4b33-9c85-21d298da0223 | cirros-0.5.1-x86_64-disk | active |
+--------------------------------------+--------------------------+--------+
```

List the available networks

```bash
openstack network list
```

```bash
+--------------------------------------+---------+----------------------------------------------------------------------------+
| ID                                   | Name    | Subnets
      |
+--------------------------------------+---------+----------------------------------------------------------------------------+
| 2526aa80-f92d-421e-a157-72e2812de673 | public  | 3ed868bf-5777-47d8-a0c3-3e7af01a7e71, 99632ce3-f685-4a77-9893-be8397d504f9 |
| 5b85e117-de84-41ae-b9ce-ceec9eb679ad | private | 1b1f519c-90f2-411f-b4f2-87444d7d8b66, 1dc4167f-dff3-428f-a994-648dab73f968 |
+--------------------------------------+---------+----------------------------------------------------------------------------+
```

List the available keypairs

```bash
openstack keypair list
```

```bash
+------------------+-------------------------------------------------+
| Name             | Fingerprint                                     |
+------------------+-------------------------------------------------+
| miclaveopenstack | c5:cd:88:ce:56:b9:02:0a:01:95:4d:80:c2:83:ee:3d |
+------------------+-------------------------------------------------+
```

Create the instance

```bash
openstack server create --flavor cirros256 \
 --image cirros-0.5.1-x86_64-disk \
 --nic net-id=5b85e117-de84-41ae-b9ce-ceec9eb679ad \
 --security-group default --key-name miclaveopenstack vm_prueba1
```

```bash
+-----------------------------+-----------------------------------------------------------------+
| Field                       | Value                                                           |
+-----------------------------+-----------------------------------------------------------------+
| OS-DCF:diskConfig           | MANUAL                                                          |
| OS-EXT-AZ:availability_zone |                                                                 |
| OS-EXT-STS:power_state      | NOSTATE                                                         |
| OS-EXT-STS:task_state       | scheduling                                                      |
| OS-EXT-STS:vm_state         | building                                                        |
| OS-SRV-USG:launched_at      | None                                                            |
| OS-SRV-USG:terminated_at    | None                                                            |
| accessIPv4                  |                                                                 |
| accessIPv6                  |                                                                 |
| addresses                   |                                                                 |
| adminPass                   | okUPki7CFjuS                                                    |
| config_drive                |                                                                 |
| created                     | 2022-05-24T08:20:39Z                                            |
| flavor                      | cirros256 (c1)                                                  |
| hostId                      |                                                                 |
| id                          | 32c37de9-dc14-4ca3-b394-1a39b3ea0ed2                            |
| image                       | cirros-0.5.1-x86_64-disk (bea36c5c-3eea-4b33-9c85-21d298da0223) |
| key_name                    | miclaveopenstack                                                |
| name                        | vm_prueba1                                                      |
| progress                    | 0                                                               |
| project_id                  | 9f0d6ceacecd4060b34061f63d17dff5                                |
| properties                  |                                                                 |
| security_groups             | name='a63840f5-2496-4643-b7dd-d9da8aaeb52e'                     |
| status                      | BUILD                                                           |
| updated                     | 2022-05-24T08:20:39Z                                            |
| user_id                     | b4335fcca296491db15466aa1c231985                                |
| volumes_attached            |                                                                 |
+-----------------------------+-----------------------------------------------------------------+
```

Request a floating IP

```bash
openstack floating ip create public
```

Associate the floating IP to the created instance

```bash
openstack server add floating ip vm_prueba1 192.168.56.237
```

Give the appropriate permissions to our key

```bash
chmod 600 miclaveopenstack.pem
```

Connect to the instance by SSH from Devstack Host

```BASH
ssh -i ./miclaveopenstack.pem cirros@192.168.56.237
```

#### `We also could connect via SSH to the instance from any physical or virtual machine that is in the network range 192.168.56.0/24.`

Another way to access the instance will be through the VNC console

```bash
http://localhost:6080/vnc_lite.html?path=%3Ftoken%3D46251952-adc1-4108-8db0-7ce27af25cc8&title=vm_prueba1(32c37de9-dc14-4ca3-b394-1a39b3ea0ed2)
```
