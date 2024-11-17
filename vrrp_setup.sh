#!/bin/bash

HOSTNAME=$(hostname)

if [ "$HOSTNAME" == "vrrp-master" ]; then
    KEEPALIVED_STATE='MASTER'
    KEEPALIVED_PRIORITY=100
elif [ "$HOSTNAME" == "vrrp-backup" ]; then
    KEEPALIVED_STATE='BACKUP'
    KEEPALIVED_PRIORITY=50
else
    echo "invalid hostname $HOSTNAME for install script $0";
    exit 1;
fi

IP=$(ip addr | grep inet | grep ens3 | awk '{print $2}' | cut -d'/' -f1)

echo "$IP $HOSTNAME" >> /etc/hosts

apt-get update
apt-get -y install keepalived

echo "vrrp_instance vrrp_group_1 {
    state $KEEPALIVED_STATE
    interface ens3
    virtual_router_id 1
    priority $KEEPALIVED_PRIORITY
    authentication {
        auth_type PASS
        auth_pass password
    }
    virtual_ipaddress {
        10.10.10.200/24 brd 10.10.10.255 dev ens3
    }
}" > /etc/keepalived/keepalived.conf

apt-get -y install apache2
echo "$HOSTNAME" > /var/www/html/index.html
service keepalived restart

echo "Configuring NAT"
sudo iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
