#!/bin/bash

fdisk /dev/sda <<EOF
d
n
p



w
EOF

partprobe /dev/sda

