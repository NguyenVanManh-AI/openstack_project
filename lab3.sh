#!/bin/bash

# Create keypair and grant access permissions
echo "Create keypair and grant access permissions"
microstack.openstack keypair create keyManh > keyManh.pem
sudo chmod 400 keyManh.pem

# Create network and subnet for Office-Net
echo "Create network and subnet for Office-Net"
microstack.openstack network create Office-Net
microstack.openstack subnet create --network Office-Net --subnet-range 10.10.10.0/24 --gateway 10.10.10.1 --allocation-pool start=10.10.10.10,end=10.10.10.50 Office-Sub

# Create network and subnet for Lab-Net
echo "Create network and subnet for Lab-Net"
microstack.openstack network create Lab-Net
microstack.openstack subnet create --network Lab-Net --subnet-range 192.168.101.0/24 --gateway 192.168.101.1 --allocation-pool start=192.168.101.10,end=192.168.101.50 Lab-Sub

# Create and configure Router
echo "Create and configure Router"
microstack.openstack router create I-Router
microstack.openstack router set I-Router --external-gateway external
microstack.openstack router add subnet I-Router Office-Sub
microstack.openstack router set --route destination=192.168.101.0/24,gateway=10.10.10.254 I-Router

# Create Lab-Router and connect to Lab-Sub subnet
echo "Create Lab-Router and connect to Lab-Sub subnet"
microstack.openstack router create Lab-Router
microstack.openstack router add subnet Lab-Router Lab-Sub

# Create port for Office-Net and assign IP
echo "Create port for Office-Net and assign IP"
OfficeNetPortID=$(microstack.openstack port create --network Office-Net --fixed-ip subnet=Office-Sub,ip-address=10.10.10.254 Office-Net-Port -f value -c id)
microstack.openstack router add port Lab-Router $OfficeNetPortID

# Configure default route for Lab-Router
echo "Configure default route for Lab-Router"
microstack.openstack router set --route destination=0.0.0.0/0,gateway=10.10.10.1 Lab-Router

# Create port for Office-Net and assign IP
echo "Create port for Office-Net and assign IP"
OfficePortID=$(microstack.openstack port create --network Office-Net --fixed-ip subnet=Office-Sub,ip-address=10.10.10.100 Office-Port -f value -c id)

# Create Office-VM server and assign port
echo "Create Office-VM server and assign port"
microstack.openstack server create --flavor m1.tiny --image cirros --key-name keyManh --security-group default --port $OfficePortID Office-VM

# Create Floating IP and assign to Office-VM
echo "Create Floating IP and assign to Office-VM"
FloatingIP=$(microstack.openstack floating ip create external -f value -c floating_ip_address)
microstack.openstack server add floating ip Office-VM $FloatingIP

# Create port for Lab-Net and assign IP
echo "Create port for Lab-Net and assign IP"
LabPortID=$(microstack.openstack port create --network Lab-Net --fixed-ip subnet=Lab-Sub,ip-address=192.168.101.100 Lab-Port -f value -c id)

# Create Lab-VM server and assign port
echo "Create Lab-VM server and assign port"
microstack.openstack server create --flavor m1.tiny --image cirros --key-name keyManh --security-group default --port $LabPortID Lab-VM

echo "Setting router external gateway"
microstack.openstack router set --external-gateway external I-Router

echo "Enabling IP forwarding"
sudo sysctl -w net.ipv4.ip_forward=1

echo "Configuring NAT"
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

echo "microstack.openstack server list"
microstack.openstack server list

echo "ssh -i keyManh.pem cirros@$FloatingIP"
echo "Office-VM: ping 192.168.101.100 , ping 8.8.8.8"

echo "Office-VM into Lab-VM : ssh cirros@192.168.101.100"
echo "Lab-VM: ping 10.10.10.100 , ping 8.8.8.8"

echo "Setup completed !"


