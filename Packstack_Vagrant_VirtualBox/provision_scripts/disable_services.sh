#!/bin/bash -eux

echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf;
sysctl -p /etc/sysctl.conf;
sudo cat /etc/sysctl.conf | grep "net.ipv4.ip_forward";

sudo systemctl disable firewalld;
sudo systemctl stop firewalld;
sudo systemctl disable NetworkManager;
sudo systemctl stop NetworkManager;
sudo systemctl enable network;
sudo systemctl start network;