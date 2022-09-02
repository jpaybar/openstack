# Openstack CLI - Basic volume management

### 

### Description:

In this proof of concept we are going to create several instances and volumes that we will attach to these same VMs. Volumes are persistent, so they will not be deleted by deleting instances, unlike disks, which are ephemeral and are deleted by deleting them.
Once these volumes have been created, we must partition and format them, as well as mount them within the file system.

### Prerequisites for creating the instances:

### 

##### Create SSH, HTTP and ICMP connection rules and they are added to default security group

```bash
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
openstack security group rule create --proto tcp --dst-port 80 default
```

```bash
openstack security group rule list
```

![list_rules.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\list_rules.PNG)

##### Create a key pair and assign the right permissions

```bash
openstack keypair create myprivatekey > myprivatekey.pem
chmod 600 myprivatekey.pem
```

![list_keypair.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\list_keypair.PNG)

##### Create 2 Floating IP's for each server

```bash
openstack floating ip create public
```

![list_floatingIP.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\list_floatingIP.PNG)

##### Create 2 instances connected to "private" subnet

```bash
openstack server create --flavor ds512M \
 --image Debian_10 \
 --nic net-id=5b85e117-de84-41ae-b9ce-ceec9eb679ad \
 --security-group default \
 --key-name myprivatekey \
 server1 


openstack server create --flavor ds512M \
 --image Ubuntu_1804 \
 --nic net-id=5b85e117-de84-41ae-b9ce-ceec9eb679ad \
 --security-group default \
 --key-name myprivatekey \
 server2
```

##### Assign a Floating IP to each instance

```bash
openstack server add floating ip server1 192.168.56.241
openstack server add floating ip server2 192.168.56.254
```

<img title="" src="file:///C:/LABO/vagrant/OPENSTACK/Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's/images/list_servers.PNG" alt="list_servers.PNG" width="669">

### 

### Create volumes:

### 

##### Create `volume1` and `volume2`

```bash
openstack volume create volume1 --size 1
openstack volume create volume2 --size 2
```

![list_volumes.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\list_volumes.PNG)

##### Attach `volume1` to `server1` instance

openstack server add volume "server id" "volume id" --device /dev/vdb

```bash
openstack server add volume ae6782c6-ee0e-4b2b-8c49-fefdab934fb8 8195df5a-05de-4e45-ab8a-a22af3cce8c1 --device /dev/vdb
openstack server add volume aede9cae-1fd5-4e83-b030-cd304d8ca4da 2a02765d-8d9e-4620-8fed-afece93379e7 --device /dev/vdb
```

##### List the disks on `server1`

First of all, we need to connect to our server1 instance:

```bash
ssh -i myprivatekey.pem debian@192.168.56.241
```

```bash
fdisk -l
```

##### Create a primary partition on `/dev/vdb` and save it

```bash
fdisk /dev/vdb


options:
n (new partition)
p (primary partition)
w (save partition)
```

##### Format `/dev/vdb1` on `ext4` file system

```bash
mkfs.ext4 /dev/vdb1
```

![list_dev_vdb1.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\list_dev_vdb1.PNG)

##### Create `/volume1` and mount `/dev/vdb1`

```bash
mkdir /volume1
mount /dev/vdb1 /volume1
```

![mount_volum1.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\mount_volum1.PNG)

##### Create `file1.txt` and `folder1`

We create `file1.txt` and `folder1` in `volume1` that is associated to `server1`, later we will disassociate `volume1` and associate it to the `server2` instance.

![umount_volum1.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\umount_volum1.PNG)

![attach_volum1_on_server2.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\attach_volum1_on_server2.PNG)

##### Mount `volume1` "/dev/vdc1" to `/mnt` directory on `server2`

![mount_volum1_on_server2.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\mount_volum1_on_server2.PNG)

##### Create a snapshot called `snapshot_volume1` of `volume1` and attach it to `server1`

```bash
openstack volume snapshot create --volume volume1 --force snapshot_volume1
```

![create_snapshot_volume1.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Basic%20volume%20management,%20Containers,%20Objects%20and%20ACL's\images\create_snapshot_volume1.PNG)

Remove `volume1` from `server2`:

```bash
openstack server remove volume server2 volume1
```

Add `snapshot_volume1` to `server1`:

```bash
openstack server add volume ae6782c6-ee0e-4b2b-8c49-fefdab934fb8 8195df5a-05de-4e45-ab8a-a22af3cce8c1 --device /dev/vdb
```

### 

### Create a volume from a image

We will create a volume from a Ubuntu image, in this way the instance that we create will not have an ephemeral disk, but will be persistent even if we delete the instance, the volume will keep the data.

##### Create a volume from Ubuntu image

```bash
openstack volume create --image Ubuntu_1804 --size 5 ubuntu_volume
```

##### Create an instance `server3` from a volume `ubuntu_volume`

```bash
openstack server create --flavor ds512M \
 --volume ubuntu_volume \
 --nic net-id=5b85e117-de84-41ae-b9ce-ceec9eb679ad \
 --security-group default \
 --key-name myprivatekey \
 server3
```

Install `Apache2` and create a custom `index.html`, then we will delete the instance `server3` and will create `server4` from `ubuntu_volume` , so our instance called `server4` will run "Apache2" with the costume page for `server3` 

```bash
openstack server create --flavor ds512M \
 --volume ubuntu_volume \
 --nic net-id=5b85e117-de84-41ae-b9ce-ceec9eb679ad \
 --security-group default \
 --key-name myprivatekey \
 server4
```

```bash
ubuntu@server4:~$ cat /var/www/html/index.html
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>TEST PAGE ON SERVER3</title>
  </head>

  <body>
    <h1>APACHE2 TEST PAGE ON SERVER3</h1>
  </body>
</html>
```

Author Information
------------------

Juan Manuel Payán Barea    (IT Technician)   [st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com)

[jpaybar (Juan M. Payán Barea) · GitHub](https://github.com/jpaybar)

https://es.linkedin.com/in/juanmanuelpayan
