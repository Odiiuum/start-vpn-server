#!/bin/bash

# Update and install packages
apt update && apt upgrade -y

# Create user and assign password and add user to sudo group
useradd -m -s /bin/bash serg
echo "serg:csPDWnWK2020" | chpasswd
usermod -aG sudo serg

# Run vpn-install/ipsec/install.sh script
bash ipsec/install.sh

# Edit file /etc/xl2tpd/xl2tpd.conf

# Get IP range input from user
read -p "Enter IP range (e.g. 10.10.10.100-10.10.10.254): " ip_range

# Get the first IP address from the range
local_ip=$(echo $ip_range | cut -d '-' -f 1 | awk -F'.' '{print $1"."$2"."$3".1"}')

# Update xl2tpd.conf with user input
sed -i "s/ip range = .*/ip range = $ip_range/g" /etc/xl2tpd/xl2tpd.conf
sed -i "s/local ip = .*/local ip = $local_ip/g" /etc/xl2tpd/xl2tpd.conf

# Update options.xl2tpd with MTU and MRU settings
sed -i "s/^mtu.*/mtu 1400/g" /etc/ppp/options.xl2tpd
sed -i "s/^mru.*/mru 1400/g" /etc/ppp/options.xl2tpd

# Restart services
systemctl restart xl2tpd
systemctl restart strongswan-starter
ipsec restart

# Disable root login via SSH
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
systemctl restart sshd