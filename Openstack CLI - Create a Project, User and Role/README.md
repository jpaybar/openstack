# Openstack CLI - Create a Project, User and Role

### 

### Description:

We are going to create a new project called `project1` with the associated user `project1` and a role of type `member`. For this, `Keystone`, the OpenStack component in charge of authentication and authorization, uses a role-based access control mechanism `RBAC`.
Subsequently, the user `project1` must create the internal network along with the associated subnet and the router that will communicate with the initial public network created by Openstack.

##### Let's take a look at the list of Openstack projects and users:

```bash
source admin-openrc.sh
openstack project list
openstack user list
```

![Project_user_list.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Create%20a%20Project,%20User%20and%20Role\images\Project_user_list.PNG)

The `admin` project is obviously used by the administrator, `service` is the one used by the OpenStack components and users of these services (Nova, Glance, Cinder, Neutron, etc.) and `demo` is a project created in this installation to make
tests with a non-privileged user. To create a new project we will run these commands.

##### Create a new project `project1` and its user `project1`

```bash
openstack project create project1
openstack user create project1 --password openstack
```

##### Add user `project1` to role `member`

`Keystone`, the OpenStack component in charge of authentication and authorization, uses an access control mechanism based on roles `RBAC`, in this case what we want is that the user `project1` has the role `member` in the project `project1`.

Let's see the list of roles available in Openstack:

```bash
openstack role list
```

![role_list.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Create%20a%20Project,%20User%20and%20Role\images\role_list.PNG)

```bash
openstack role add --project project1 --user project1 member
```

##### Create a basic network infrastructure in the user's project `project1`

When the user `project1` logs in to `Horizon` within the project `project1` the only thing he will see in the Network Topology will be the "public" network. Each user must create the basic network scenario by adding the "private" network and its associated "private-subnet" subnet in addition to the router "router1" connected to the "public" network.

![basic_network_topologhy.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Create%20a%20Project,%20User%20and%20Role\images\basic_network_topologhy.PNG)

```bash
source project1-openrc.sh
openstack network create private
openstack subnet create --network private --subnet-range 10.0.0.0/24 --dns-nameserver 1.1.1.1 private-subnet
openstack router create router1
openstack router set router1 --external-gateway public
openstack router add subnet router1 private-subnet
```

![User_network.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Create%20a%20Project,%20User%20and%20Role\images\User_network.PNG)

### Other related commands:

##### Delete project `project1`:

```bash
openstack project delete project1
```

##### Delete user `project1`:

```bash
openstack user delete project1
```

##### Set up a password for user `project1`:

```bash
openstack user set --password openstack project1
```

##### List hypervisor:

```bash
openstack hypervisor list
```

##### List services:

```bash
openstack service list
```

![Hypervisor_servicios.PNG](C:\LABO\vagrant\OPENSTACK\Openstack%20CLI%20-%20Create%20a%20Project,%20User%20and%20Role\images\Hypervisor_servicios.PNG)

Author Information
------------------

Juan Manuel Payán Barea    (IT Technician)   [st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com)

[jpaybar (Juan M. Payán Barea) · GitHub](https://github.com/jpaybar)

https://es.linkedin.com/in/juanmanuelpayan
