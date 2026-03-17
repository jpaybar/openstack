# How to Deploy OpenStack with Sunbeam on a Single-Node VM

###### By Juan Manuel Payán / jpaybar

st4rt.fr0m.scr4tch@gmail.com

---

## 📌 Overview

This project provides a fully automated lab to deploy OpenStack using Sunbeam on a single-node Ubuntu virtual machine running on KVM.

It includes VM provisioning, system preparation, and OpenStack deployment using a reproducible and script-driven approach.

The goal is to simplify the installation process while offering a practical environment for learning, testing, and experimentation.

---

## 🧪 Environment

The lab has been tested with the following setup:

### 🖥️ Host System

- OS: Ubuntu 24.04
- CPU: AMD Ryzen 5 3600 (6 cores)
- RAM: 32 GB
- Storage: NVMe SSD
- Network: Ethernet / Wi-Fi

### ⚙️ Virtualization

- Hypervisor: KVM (libvirt)
- Network: Default libvirt network + custom routing via libvirt hook (floating IP access)

### 💻 Virtual Machine

- OS: Ubuntu Server 24.04
- vCPU: 8
- RAM: 20 GB
- Disks: 2 × 200 GB
- Network Interfaces: 2 (management + external)
- Cloud-init enabled

### ☁️ OpenStack Deployment

- Platform: OpenStack (2024.1 - Caracal)
- Method: Sunbeam (single-node)
- Deployment: Manifest-based + automated scripts

---

## 🌐 Network Topology

This setup uses a dual-network configuration to enable external access to OpenStack instances via floating IPs.

```
Physical Network (192.168.1.0/24)
        |
        |
Host (192.168.1.155)
        |
        |
KVM Hypervisor (libvirt)
virbr0 NAT -> 192.168.122.1
        |
        |
OpenStack VM
----------------------------------------
enp1s0 -> 192.168.122.250 (management)
enp2s0 -> no IP (external)
----------------------------------------
        |
        |
br-ex (Neutron external bridge)
172.20.0.1
        |
        |
Floating Network (172.20.0.0/24)
        |
        | DNAT (Neutron)
        |
OpenStack Instance
192.168.0.X
```

---

## ⚙️ Deployment Workflow

The deployment process is fully automated and follows a structured sequence:

1. **Host Preparation**
   
   - Configure networking and routing
   - Generate SSH keys and config
   - Apply libvirt hook for floating IP access

2. **VM Provisioning**
   
   - Create and configure the virtual machine (KVM)
   - Attach disks and network interfaces
   - Inject cloud-init configuration

3. **OpenStack Bootstrap**
   
   - Initialize Sunbeam cluster
   - Prepare base services

4. **OpenStack Configuration**
   
   - Apply deployment manifest
   - Configure networking, storage, and services

5. **Validation**
   
   - Access Horizon dashboard
   - Launch test instance
   - Verify external connectivity via floating IP

---

## 🚀 Quick Start

Follow these steps to deploy OpenStack using this project:

### 1. Clone the repository

```
git clone https://github.com/jpaybar/sunbeam_openstack_deployment.git
cd sunbeam_openstack_deployment
```

### 2. Run the deployment script

```
bash scripts/main.sh
```

### 3. Wait for the process to complete

The script will automatically:

- Prepare the host environment
- Create and configure the virtual machine
- Deploy OpenStack using Sunbeam
- Apply the manifest configuration

### 4. Access OpenStack

Once the deployment is complete:

- Access Horizon dashboard via browser
- Use the generated credentials
- Launch a test instance

### 5. Verify connectivity

- Assign a floating IP
- Test external access (SSH / ping)

---

## 📂 Project Structure

The repository is organized to separate automation scripts, configuration files, and supporting assets:

```
.
├── docs/
│   └── notes.md
│
├── pics/
│   ├── 01_cluster_bootstrap.png
│   ├── 02_sunbeam_configure_step1.png
│   ├── 03_sunbeam_configure_step2.png
│   ├── 04_deployment_complete.png
│   ├── 05_horizon_dashboard.png
│   └── 06_test_instance.png
│
├── scripts/
│   ├── host_config.sh        # Host preparation (SSH, routing, libvirt hook)
│   ├── main.sh               # Main orchestration script
│   └── vm_deployment.sh      # VM creation and configuration (KVM/libvirt)
│
├── manifest_deployment.yaml  # Sunbeam deployment manifest
├── user-data.template.yaml   # Cloud-init template (SSH key injection)
│
└── README.md
```

### 🔧 Script Overview

- **main.sh**  
  Entry point of the project. Orchestrates the full deployment workflow.

- **host_config.sh**  
  Prepares the host system:
  
  - SSH key generation and configuration  
  - Network setup  
  - Custom routing via libvirt hook (floating IP access)

- **vm_deployment.sh**  
  Handles virtual machine provisioning:
  
  - VM creation using KVM/libvirt  
  - Disk and network configuration  
  - Cloud-init injection using template  

### 📁 Other Components

- **manifest_deployment.yaml**  
  Defines the OpenStack deployment configuration used by Sunbeam.

- **user-data.template.yaml**  
  Cloud-init template used to configure the VM dynamically (e.g., SSH key injection).

- **pics/**  
  Contains screenshots of the deployment process and validation steps.

- **docs/**  
  Additional notes and references related to the lab.

---

## ⚠️ Important Notes (Before You Start)

Before running the deployment, make sure to review the following:

- **VM image directory (libvirt)**  
  
  Default path (not used in this project):
  
  ```
  /var/lib/libvirt/images/
  ```
  
  Custom path used in this lab:
  
  ```
  /var/lib/libvirt/user-images/openstack/
  ```
  
  This approach helps:
  
  - Keep OpenStack-related images isolated  
  - Avoid conflicts with default libvirt storage  
  - Improve organization and maintainability  

- **Disk sizing requirements**  
  
  This lab is designed to work with the following disk configuration:
  
  - System disk: **200 GB**
  - Additional storage disk: **200 GB**
  
  If you need to download and prepare the base Ubuntu image:
  
  ```
  wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
  ```
  
  Then resize it before deployment:
  
  ```
  qemu-img resize noble-server-cloudimg-amd64.img 200G
  ```

👉 Additional details and explanations are available in:
docs/notes.md

---

## 🚀 OpenStack Deployment (Lab Execution)

### ✅ Commands used in this lab (automated deployment)

The OpenStack deployment in this lab is executed using a **manifest-based automated approach**:

```bash
sudo snap install openstack

sunbeam prepare-node-script --bootstrap | bash -x && newgrp snap_daemon

sunbeam cluster bootstrap \
  --role control,compute,storage \
  --manifest manifest_deployment.yaml \
  --accept-defaults

sunbeam configure \
  --manifest manifest_deployment.yaml \
  --accept-defaults

sunbeam openrc > admin-openrc

source admin-openrc

sunbeam launch ubuntu --name test
```

💡 This approach ensures:

- Fully reproducible deployment  
- No manual interaction required  
- Consistent configuration using `manifest_deployment.yaml`  

---

## 📸 Reference: Manual / Interactive Deployment (for understanding)

> ⚠️ The following screenshots correspond to a **manual (interactive) deployment**,  
> included for educational purposes to understand what the manifest automates.

---

### 🔧 Cluster Bootstrap (interactive)

![Cluster Bootstrap](pics/01_cluster_bootstrap.png)

💡 In manual mode, this step asks for:

- Management network (CIDR)
- API IP ranges
- Storage devices (Ceph)
- Node roles

👉 In this lab, all of this is defined in the **manifest**, so no prompts appear.

---

### 🌐 OpenStack Configuration (interactive)

![Configure Step 1](pics/02_sunbeam_configure_step1.png)

![Configure Step 2](pics/03_sunbeam_configure_step2.png)

💡 Manual configuration includes:

- External network definition  
- Gateway and allocation ranges  
- Demo user and project creation  
- DNS and security rules  
- Network interface mapping  

👉 Again, all handled automatically via the manifest in this lab.

---

### ⚙️ Manifest-based deployment result

![Deployment Complete](pics/04_deployment_complete.png)

💡 This is what you actually get in this lab:

- No questions asked  
- Direct configuration from manifest  
- Faster and reproducible deployment  

---

### 🌐 Horizon Dashboard

![Horizon Login](pics/05_horizon_dashboard.png)

Access:

```
http://<OPENSTACK_VM_IP>/openstack-horizon
```

---

### 🖥️ Test Instance

![Test Instance](pics/06_test_instance.png)

💡 Final validation:

- Instance successfully launched  
- Networking working (internal + floating IP)  
- Cloud fully operational  

---

## 🧠 Key Concept

- **Interactive mode** → Learning & debugging  
- **Manifest mode (this lab)** → Automation & reproducibility  

👉 The manifest is essentially a **declarative version of the interactive setup**

---

## 📚 Official Documentation

For detailed technical information and advanced configuration, refer to the official OpenStack Sunbeam documentation:

🔗 https://canonical-openstack.readthedocs-hosted.com/en/latest/

---

### 🧠 Why this matters

- Provides in-depth explanations of each service  
- Covers advanced configurations beyond this lab  
- Useful for troubleshooting and real-world scenarios  

---

👉 This project focuses on a **practical and simplified deployment**,  
while the official documentation provides the **complete technical reference**

## Author Information

Juan Manuel Payán Barea  
Systems Administrator | SysOps | IT Infrastructure  

st4rt.fr0m.scr4tch@gmail.com  

GitHub: https://github.com/jpaybar  
LinkedIn: https://es.linkedin.com/in/juanmanuelpayan
