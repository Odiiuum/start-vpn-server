#!/bin/bash

# Update and install packages
apt update && apt upgrade -y

# Create user and assign password and add user to sudo group
read -p "Enter new username: " NEW_USER
read -p "Enter new password: " NEW_PASSWORD

useradd -m -s /bin/bash $NEW_USER
echo "$NEW_USER:$NEW_PASSWORD" | chpasswd

#Change privilegies 
chmod -R 700 /root/start-vpn-install/

# Run vpn-install/ipsec/install.sh script
bash /root/start-vpn-server/ipsec/install.sh

# Edit file /etc/xl2tpd/xl2tpd.conf

# Get IP range input from user
read -p "Enter IP range (e.g. 10.10.10.100-10.10.10.254): " ip_range

# Get the first IP address from the range
local_ip=$(echo $ip_range | cut -d '-' -f 1 | awk -F'.' '{print $1"."$2"."$3".1"}')
subnet="${local_ip%.*}.0/24"

# Update xl2tpd.conf with user input
sed -i "s/ip range = .*/ip range = $ip_range/g" /etc/xl2tpd/xl2tpd.conf
sed -i "s/local ip = .*/local ip = $local_ip/g" /etc/xl2tpd/xl2tpd.conf

# Update options.xl2tpd with MTU and MRU settings
sed -i "s/^mtu.*/mtu 1400/g" /etc/ppp/options.xl2tpd
sed -i "s/^mru.*/mru 1400/g" /etc/ppp/options.xl2tpd

# Set up SNAT rule
ext_ip=$(curl -s http://checkip.amazonaws.com)
sudo iptables -t nat -A POSTROUTING -s $subnet -j SNAT --to-source $ext_ip
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Restart services
systemctl restart xl2tpd
systemctl restart strongswan-starter.service
ipsec restart

# Disable root login via SSH
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
systemctl restart sshd
