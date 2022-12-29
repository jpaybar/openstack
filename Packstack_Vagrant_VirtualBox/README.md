# Packstack - Vagrant - VirtualBox on Centos7

###### By Juan Manuel Payán / jpaybar

st4rt.fr0m.scr4tch@gmail.com

This Vagrantfile boots a Centos 7 virtual machine and prepares the environment for Packstack installation using some Vagrant plugins.

The Vagrant box starts a virtual machine that uses VirtualBox as a provider. 

You may download de box from the official Centos Vagrant hub:

https://app.vagrantup.com/centos/boxes/7/versions/2004.01/providers/virtualbox.box

##### Environment:

- Host, Windows 10 (20H2 version) x64, Intel(R) Core(TM) i5 3.10GHz, 16GB RAM, 256GB SSD Disk

- VirtualBox 6.1.28 

- Vagrant 2.2.19

- VM Centos 7, 4 CPUs, 8 GB RAM, 1 Ethernet (192.168.56.15)

- Packstack Train version

##### Vagrant Plugins:

- vagrant-hostmanager (1.8.9, global) (required)

- vagrant-proxyconf (2.0.10, global) (optional)

- vagrant-disksize (0.1.3, global) (required)

- vagrant-reload (0.0.1, global) (required)

##### Vagrantfile:

**NOTE:**

If you are behind a proxy of a corporate network, remember to modify the IP or URL of your proxy server:

```ruby
if Vagrant.has_plugin?("vagrant-proxyconf")
        config.proxy.http     = "http://your.proxy.here:8080"
        config.proxy.https    = "http://your.proxy.here:8080"
        config.proxy.no_proxy = "localhost,127.0.0.1,192.168.56.0/24,10.0.0.0/24"
end
```

```ruby
# -*- mode: ruby -*-

# vi: set ft=ruby :

boxes = [
    {
        :name => "packstack-node1.domain.local", 
        :eth1 => "192.168.56.15",
        :mem => "8192",
        :cpu => "4",
        :box => "centos-7.8",
        :sshport => "22200",
        :horizon => "8888",
        :novnc_console => "6080",
        :group => "/packstack"
    }
]

Vagrant.configure(2) do |config|

    if Vagrant.has_plugin?("vagrant-proxyconf")
        config.proxy.http     = "http://your.proxy.here:8080"
        config.proxy.https    = "http://your.proxy.here:8080"
        config.proxy.no_proxy = "localhost,127.0.0.1,192.168.56.0/24,10.0.0.0/24"
    end

    if Vagrant.has_plugin?("vagrant-vbguest") then
          config.vbguest.auto_update = false
    end

    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.manage_guest = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true

    boxes.each do |opts|
        config.ssh.insert_key = false
        config.vm.define opts[:name] do |subconfig|
            subconfig.vm.box = opts[:box]
            subconfig.vm.hostname = opts[:name]
            subconfig.vm.network "private_network", ip: opts[:eth1]
            subconfig.vm.network "forwarded_port", guest: 22, host: opts[:sshport], id: "ssh"
            subconfig.vm.network "forwarded_port", guest: 80, host: opts[:horizon], id: "horizon"
            subconfig.vm.network "forwarded_port", guest: 6080, host: opts[:novnc_console], id: "novnc_console"
            subconfig.vm.synced_folder ".", "/vagrant", type: "rsync", id: "Directorio de Packstack",
                rsync__exclude: ".git/"
            subconfig.vm.provider "virtualbox" do |vb|
                vb.customize ["modifyvm", :id, "--name", opts[:name]]
                vb.customize ["modifyvm", :id, "--memory", opts[:mem]]
                vb.customize ["modifyvm", :id, "--cpus", opts[:cpu]]
                vb.customize ["modifyvm", :id, "--groups", opts[:group]]
                vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
                vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
            end
            subconfig.vm.post_up_message = "MÁQUINA VIRTUAL OK"
        end
    end
    config.disksize.size = '80GB'
    config.vm.provision "shell", path: "provision_scripts/resize_hdd.sh"
    config.vm.provision "shell", preserve_order: true, path: "provision_scripts/yum_update.sh"
    config.vm.provision :reload
    config.vm.provision "shell", preserve_order: true, path: "provision_scripts/disable_services.sh"
    config.vm.provision :reload
    config.vm.provision "shell", preserve_order: true, path: "provision_scripts/config_selinux.sh"
    config.vm.provision :reload
    config.vm.provision "shell", preserve_order: true, path: "provision_scripts/install_packstack_release.sh"
    config.vm.provision :reload
    config.vm.provision "shell", preserve_order: true, path: "provision_scripts/install_packstack.sh"
    config.vm.provision :reload
    config.vm.provision "shell", preserve_order: true, path: "provision_scripts/answer_file.sh"
end
```

### Quick start:

Clone the repository

```bash
git clone https://github.com/jpaybar/OpenStack.git
```

```bash
cd Packstack_Vagrant_VirtualBox
```

```bash
vagrant up
```

Once the virtual machine has booted, log in via ssh:

```bash
vagrant ssh
```

Everything is ready to start the installation, an answer file will have been generated and we only have to run the following command:

```bash
sudo packstack --answer-file=packstack-answers.txt
```

When the installation finishes, we will see something similar to this screen:

![Installation_OK.PNG](https://github.com/jpaybar/OpenStack/blob/main/Packstack_Vagrant_VirtualBox/_images/Installation_OK.PNG)

As we can see, it shows us that we can access "Horizon" from the following url:

http://192.168.56.15/dashboard

But in our Vagrantfile we have forwarded the 80 port of the Guest to 8888 of our Host:

The Horizon login window will be accessible through http://localhost:8888

![Horizon_screen.PNG](https://github.com/jpaybar/OpenStack/blob/main/Packstack_Vagrant_VirtualBox/_images/Horizon_screen.PNG)

User/passwd "admin/openstack"

To use the Openstack CLI we need to call the script that contains the API variables and that is located in the "root" user directory, as the information shows us after the installation:

```bash
[vagrant@packstack-node1 ~]$ sudo ls -l /root/
total 20
-rw-------. 1 root root 5570 Apr 30  2020 anaconda-ks.cfg
-rw-------. 1 root root  366 Nov  2 09:44 keystonerc_admin
-rw-------. 1 root root 5300 Apr 30  2020 original-ks.cfg
```

But first, we must do some configuration in the network by modifying our network card "ifcfg-eth1" and creating another one in bridge mode "ifcfg-br-ex" among other changes.

### Post-install configuration

Run next commands

```bash
cd /vagrant/post_install_scripts/
./setup_bridge_network.sh
```

### Creating the basic network infrastructure

Now we need to create a public network "ext" and its subnet, we will also create a private network with its corresponding subnet. We will link both networks with a router.
Finally we will download an image of Ubuntu 18.04, will upload it to Openstack, will create our own flavor, will add a pair of SSH keys, etc... and will create an instance to which will assign a Floating IP.
To automate the entire process as in the previous step, we will execute a script called `basic_network_setup.sh`, but first of all, we should source our RC file:

```bash
sudo -i
source keystonerc_admin
```

```bash
cd /vagrant/network_setup_scripts/
./basic_network_setup.sh
```

Once the script has finished executing we will have the following network structure with our Ubuntu 18.04 instance.

![Basic_network.PNG](https://github.com/jpaybar/OpenStack/blob/main/Packstack_Vagrant_VirtualBox/_images/Basic_network.PNG)

We also could connect via SSH to the instance from any physical or virtual machine that is in the network range 192.168.56.0/24.

```bash
openstack server list
+--------------------------------------+-----------------+--------+------------------------------------+--------------+---------+
| ID                                   | Name            | Status | Networks                           | Image        | Flavor  |
+--------------------------------------+-----------------+--------+------------------------------------+--------------+---------+
| fcef855f-074d-4cd3-997f-c67029c41c68 | Ubuntu_18.04_VM | ACTIVE | private=10.0.0.172, 192.168.56.246 | Ubuntu_18.04 | MY.tiny |
+--------------------------------------+-----------------+--------+------------------------------------+--------------+---------+
```

```bash
vagrant@masterVM:~$ ip a | grep enp0s8
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet 192.168.56.20/24 brd 192.168.56.255 scope global enp0s8
vagrant@masterVM:~$ ping -c3 192.168.56.246
PING 192.168.56.246 (192.168.56.246) 56(84) bytes of data.
64 bytes from 192.168.56.246: icmp_seq=1 ttl=63 time=1.66 ms
64 bytes from 192.168.56.246: icmp_seq=2 ttl=63 time=2.15 ms
64 bytes from 192.168.56.246: icmp_seq=3 ttl=63 time=1.40 ms

--- 192.168.56.246 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 1.397/1.735/2.149/0.311 ms
```

So, let's connect from another machine called masterVM with IP 192.168.56.20 to our instance with Floating IP 192.168.56.246:

**NOTE:**

**Don't forget to assign the correct permissions to the SSH key generated by the script.**

```bash
chmod 600 mykeypair.pem
```

```bash
ssh -i mykeypair.pem ubuntu@192.168.56.246
```

```bash
Welcome to Ubuntu 18.04.6 LTS (GNU/Linux 4.15.0-194-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Wed Nov  2 11:49:36 UTC 2022

  System load:  0.08              Processes:           82
  Usage of /:   23.9% of 4.67GB   Users logged in:     0
  Memory usage: 12%               IP address for ens3: 10.0.0.172
  Swap usage:   0%

0 updates can be applied immediately.



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ubuntu@ubuntu-18:~$
```

Another way to access the instance is through the VNC console:

```bash
http://192.168.56.15:6080/vnc_auto.html?path=%3Ftoken%3Ddbc4c651-d8a3-462d-936a-898c1332c159&title=Ubuntu_18.04_VM(fcef855f-074d-4cd3-997f-c67029c41c68)
```

But, we will have to substitute the IP of our Openstack (192.168.56.15) for localhost in the generated URL, as follows:

```bash
http://localhost:6080/vnc_auto.html?path=%3Ftoken%3Ddbc4c651-d8a3-462d-936a-898c1332c159&title=Ubuntu_18.04_VM(fcef855f-074d-4cd3-997f-c67029c41c68)
```

## Author Information

Juan Manuel Payán Barea    (IT Technician) [st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com)

[jpaybar (Juan M. Payán Barea) · GitHub](https://github.com/jpaybar)

https://es.linkedin.com/in/juanmanuelpayan
