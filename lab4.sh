#!/bin/bash

echo "Downloading the vrrp_setup.sh file"
sudo wget -O vrrp_setup.sh https://raw.githubusercontent.com/NguyenVanManh-AI/openstack_project/main/vrrp_setup.sh 

echo "Granting execute permissions for vrrp_setup.sh"
sudo chmod +x vrrp_setup.sh

echo "Setting permissions for the directory"
sudo chmod -R 777 vrrp_setup.sh

echo "Creating network Server-Net"
microstack.openstack network create Server-Net

echo "Creating subnet for Server-Net"
microstack.openstack subnet create --network Server-Net --subnet-range 10.10.10.0/24 --gateway 10.10.10.1 --allocation-pool start=10.10.10.10,end=10.10.10.50 Server-Subnet

echo "Creating keypair and saving it in keyManh.pem"
microstack.openstack keypair create keyManh > keyManh.pem

echo "Setting read-only permissions for keyManh.pem file"
sudo chmod 400 keyManh.pem

echo "Creating router"
microstack.openstack router create I-Router

echo "Setting external gateway for the router (Public network)"
microstack.openstack router set --external-gateway external I-Router

echo "Adding interface to the router, connecting to the Server-Net network"
microstack.openstack router add subnet I-Router Server-Subnet

echo "Creating ports with fixed IPs for master and slave VM"
microstack.openstack port create --network Server-Net --fixed-ip subnet=Server-Subnet,ip-address=10.10.10.100 Server-Port-1
microstack.openstack port create --network Server-Net --fixed-ip subnet=Server-Subnet,ip-address=10.10.10.101 Server-Port-2

echo "Creating Master  VM with ubuntu16  image and m1.small flavor"
PORT_ID_MASTER=$(sudo microstack.openstack port show Server-Port-1 -f value -c id)
microstack.openstack server create --image ubuntu16  --flavor m1.small --key-name keyManh --nic port-id=$PORT_ID_MASTER --user-data vrrp_setup.sh vrrp-master

echo "Creating Slave  VM with ubuntu16  image and m1.small flavor"
PORT_ID_SLAVE=$(sudo microstack.openstack port show Server-Port-2 -f value -c id)
microstack.openstack server create --image ubuntu16   --flavor m1.small --key-name keyManh --nic port-id=$PORT_ID_SLAVE --user-data vrrp_setup.sh vrrp-slave

echo "Creating port for VRRP with fixed IP"
microstack.openstack port create --network Server-Net --fixed-ip subnet=Server-Subnet,ip-address=10.10.10.200 Server-Port-VRRP

echo "Creating Floating IP for Master VM"
FLOATING_IP_MASTER=$(microstack.openstack floating ip create external -f value -c floating_ip_address)

echo "Associating Floating IP with Master VM"
microstack.openstack server add floating ip vrrp-master $FLOATING_IP_MASTER

echo "Creating Floating IP for Slave VM"
FLOATING_IP_SLAVE=$(microstack.openstack floating ip create external -f value -c floating_ip_address)

echo "Associating Floating IP with Slave VM"
microstack.openstack server add floating ip vrrp-slave $FLOATING_IP_SLAVE

echo "Updating port with allowed address pairs"
microstack.openstack port set $PORT_ID_MASTER --allowed-address ip-address=10.10.10.200
microstack.openstack port set $PORT_ID_SLAVE --allowed-address ip-address=10.10.10.200


echo "Floating IP for Slave VM: $FLOATING_IP_SLAVE"
echo "curl http://$FLOATING_IP_SLAVE"
echo "Floating IP for Master VM: $FLOATING_IP_MASTER"
echo "curl http://$FLOATING_IP_MASTER"

echo "Setting router external gateway"
microstack.openstack router set --external-gateway external I-Router

echo "Enabling IP forwarding"
sudo sysctl -w net.ipv4.ip_forward=1

echo "Configuring NAT"
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

echo "microstack.openstack server list"
microstack.openstack server list

echo "Master VM , pw root  : ssh -i keyManh.pem root@$FLOATING_IP_MASTER"
echo "Slave VM , pw root  : ssh -i keyManh.pem root@$FLOATING_IP_SLAVE"

echo "Setup completed !"



