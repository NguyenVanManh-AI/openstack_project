#!/bin/bash

# reset 
# echo "Downloading the reset_microstack.sh file"
# sudo wget -O reset_microstack.sh https://raw.githubusercontent.com/NguyenVanManh-AI/openstack_project/main/reset_microstack.sh 
# echo "Granting execute permissions for reset_microstack.sh"
# sudo chmod +x reset_microstack.sh
# sudo ./reset_microstack.sh
# reset 

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

# Chờ cho đến khi Office-VM ở trạng thái "ACTIVE"
echo "Waiting for Office-VM to become ACTIVE..."
status=$(microstack.openstack server show Office-VM -f value -c status)
while [ "$status" != "ACTIVE" ]; do
  echo "Office-VM is in status: $status. Waiting..."
  sleep 5
  status=$(microstack.openstack server show Office-VM -f value -c status)
done
# Tiếp tục khi Office-VM đã ACTIVE
echo "Office-VM is ACTIVE. Proceeding with Floating IP assignment."

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

# Chờ cho đến khi Lab-VM ở trạng thái "ACTIVE"
echo "Waiting for Lab-VM to become ACTIVE..."
status_lab=$(microstack.openstack server show Lab-VM -f value -c status)
while [ "$status_lab" != "ACTIVE" ]; do
  echo "Lab-VM is in status: $status_lab. Waiting..."
  sleep 5
  status_lab=$(microstack.openstack server show Lab-VM -f value -c status)
done
# Tiếp tục khi Lab-VM đã ACTIVE
echo "Lab-VM is ACTIVE. Proceeding with next steps."

echo "Setting router external gateway"
microstack.openstack router set --external-gateway external I-Router

echo "Enabling IP forwarding"
sudo sysctl -w net.ipv4.ip_forward=1

echo "Configuring NAT"
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

echo "microstack.openstack server list"
microstack.openstack server list

echo "ssh -i keyManh.pem cirros@$FloatingIP (password = gocubsgo)"
echo "Office-VM: ping 192.168.101.100 , ping 8.8.8.8"

echo "Office-VM into Lab-VM : ssh cirros@192.168.101.100 (password = gocubsgo)"
echo "Lab-VM: ping 10.10.10.100 , ping 8.8.8.8"

echo "Setup completed !"


