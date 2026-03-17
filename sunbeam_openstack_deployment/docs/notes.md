# 🧠 Lab Notes & Troubleshooting

This document contains internal notes, troubleshooting steps, and design decisions made during the development of this OpenStack Sunbeam lab.

---

## 🛠️ Known Issues

### ❌ Libvirt permissions (root issue)

**Problem**

Running VM deployment scripts with `sudo` caused libvirt resources to be owned by root.

**Symptoms**

- Permission denied errors
- Cloud-init ISO not attaching
- VM inconsistencies

**Fix**

Run scripts as a regular user.  
Ensure proper group membership if needed:

```
sudo usermod -aG libvirt $USER
newgrp libvirt
```

---

### ⚠️ Floating IP connectivity

**Problem**

Instances are not reachable from the host network.

**Cause**

Missing route between host and OpenStack floating network.

---

## 🏗️ Design Decisions

### 📁 Custom libvirt image directory

Custom path used:

```
/var/lib/libvirt/user-images/openstack/
```

Create it manually before deployment:

```
sudo mkdir -p /var/lib/libvirt/user-images/openstack/
sudo chown -R root:libvirt /var/lib/libvirt/user-images/
sudo chmod -R 775 /var/lib/libvirt/user-images/
```

Ensure your user is part of the libvirt group:

```
sudo usermod -aG libvirt $USER
newgrp libvirt
```

**Reasoning**

- Better organization
- Isolation of OpenStack resources
- Avoid conflicts with default libvirt storage
- Keeps compatibility with libvirt/qemu permission model

---

### 💾 Base image preparation

Download Ubuntu cloud image:

```
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

Resize it to match lab requirements:

```
qemu-img resize noble-server-cloudimg-amd64.img 200G
```

---

### 🌐 Networking approach (Wi-Fi host limitation)

When the host uses Wi-Fi, bridging is not viable.  
To allow access to floating IPs, a custom route is required.

> 💡 Note:  
> In a wired (Ethernet) environment, a bridge-based setup may be possible, potentially removing the need for this workaround.  
> This scenario has not been tested in this lab.

---

## 🔧 Libvirt Hook (Routing)

### 📍 Location

```
/etc/libvirt/hooks/qemu
```

### 📄 Purpose

Automatically adds a route on the host when the VM starts.

### ⚙️ Route added

```
172.20.0.0/24 via 192.168.122.250
```

### 🧠 Why this is needed

- OpenStack floating network is isolated
- Host cannot reach it by default
- Wi-Fi prevents proper bridge configuration
- This route enables direct access to instances

---

## 🔐 VM-side networking (cloud-init + iptables)

Inside the VM, traffic forwarding and NAT are required.

### ⚙️ Injected via cloud-init

Typical rules:

```
iptables -t nat -A POSTROUTING -o br-ex -j MASQUERADE
iptables -A FORWARD -i enp1s0 -o br-ex -j ACCEPT
iptables -A FORWARD -i br-ex -o enp1s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

### 🧠 Purpose

- Enable outbound connectivity
- Allow traffic between internal and external networks
- Support floating IP NAT (Neutron)

---

## 🔧 Useful Commands

### Check VMs

```
virsh list --all
```

### Check routes

```
ip route
```

### Check VM disks

```
virsh domblklist <vm-name>
```

---

## 🧠 Lessons Learned

- Avoid using `sudo` with libvirt unless necessary
- Always prepare base images before deployment
- Networking is the most critical part
- Wi-Fi environments require routing workarounds
- Automation reduces human error significantly



## ⚙️ Additional Services (Recommended Order)

These services can be enabled after the base OpenStack deployment.

The following order is optimized for:

- ✅ Low resource usage  
- ✅ Maximum practical learning  
- ✅ Real-world relevance  

---

### 1️⃣ 🌐 Load Balancer (Octavia)

First service to enable.

Why:

- Very practical (used everywhere)
- Low overhead compared to others
- Lets you simulate real production scenarios (HA, VIPs)

```bash
sunbeam enable loadbalancer
```

---

### 2️⃣ 🏗️ Orchestration (Heat)

Second step.

Why:

- Core OpenStack service
- Enables Infrastructure-as-Code (IaC)
- Required by other services (e.g. Magnum)

```bash
sunbeam enable orchestration
```

---

### 3️⃣ ☸️ Containers (Magnum)

Optional, only if you want Kubernetes on OpenStack.

Why:

- More complex
- Depends on Heat
- Higher resource consumption

```bash
sunbeam enable container-irc
```

---

### 4️⃣ 📊 Observability (Prometheus / Grafana)

Optional.

Why:

- Useful for monitoring
- But not essential in a small lab
- Consumes additional resources

```bash
sunbeam enable observability
```

---

### 5️⃣ 🌍 DNS Configuration

Optional.

```bash
sunbeam enable dns 8.8.8.8,1.1.1.1
```

---

## 🧠 Summary

- **Start with:** Loadbalancer + Heat  
- **Add later:** Magnum (if you go into Kubernetes)  
- **Only if needed:** Observability  

👉 This keeps the lab lightweight while still being **realistic and valuable**
