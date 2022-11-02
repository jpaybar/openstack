#!/bin/bash -eux

sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config;
sudo getenforce;
sudo touch /.autorelabel;