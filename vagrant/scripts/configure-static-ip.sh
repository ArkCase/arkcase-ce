#!/bin/sh

echo 'Setting static IP address for Hyper-V...'

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
PREFIX=24
IPADDR=172.28.128.3
GATEWAY=172.28.128.1
DNS1=8.8.8.8
EOF