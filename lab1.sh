#!/bin/bash

# reset 
# echo "Downloading the reset_microstack.sh file"
# sudo wget -O reset_microstack.sh https://raw.githubusercontent.com/NguyenVanManh-AI/openstack_project/main/reset_microstack.sh 
# echo "Granting execute permissions for reset_microstack.sh"
# sudo chmod +x reset_microstack.sh
# sudo ./reset_microstack.sh
# reset 

# Redirect all output (stdout and stderr) to log.txt
exec > >(tee -a log.txt) 2>&1

# Tạo Network và Subnet
echo "Creating network N1"
network_id=$(microstack.openstack network create N1 -f value -c id)
echo "Network ID: $network_id"

echo "Creating subnet S1"
subnet_id=$(microstack.openstack subnet create --network $network_id --allocation-pool start=10.10.10.10,end=10.10.10.50 --gateway 10.10.10.1 --subnet-range 10.10.10.0/24 S1 -f value -c id)
echo "Subnet ID: $subnet_id"

# Tạo Router và Cấu hình Gateway
echo "Creating router Router1"
microstack.openstack router create Router1

echo "Setting external gateway for Router1"
microstack.openstack router set --external-gateway external Router1

echo "Adding subnet S1 to Router1"
microstack.openstack router add subnet Router1 $subnet_id

# Kiểm tra và thêm Security Group rule nếu chưa có
echo "Allowing ICMP and SSH in the default security group"
if ! microstack.openstack security group rule list default --protocol icmp | grep -q icmp; then
  microstack.openstack security group rule create --protocol icmp default
fi

# Tạo Keypair
echo "Creating keypair keyManh"
microstack.openstack keypair create keyManh > keyManh.pem
chmod 400 keyManh.pem
echo "Keypair saved to keyManh.pem"

# Tạo VM1
echo "Creating VM1"
microstack.openstack server create --flavor m1.tiny --image cirros --key-name keyManh --security-group default --network $network_id VM1

# Chờ cho đến khi VM1 ở trạng thái "ACTIVE"
echo "Waiting for VM1 to become ACTIVE..."
status_vm1=$(microstack.openstack server show VM1 -f value -c status)
while [ "$status_vm1" != "ACTIVE" ]; do
  echo "VM1 is in status: $status_vm1. Waiting..."
  sleep 5
  status_vm1=$(microstack.openstack server show VM1 -f value -c status)
done
echo "VM1 is ACTIVE. Proceeding with VM2 creation."

# Tạo Port cố định cho VM2 và gán địa chỉ IP tĩnh
echo "Creating port for VM2 with fixed IP"
port_id=$(microstack.openstack port create --network $network_id --fixed-ip subnet=$subnet_id,ip-address=10.10.10.100 --security-group default my-port -f value -c id)
echo "Port ID for VM2: $port_id"

# Tạo VM2 với port cố định
echo "Creating VM2 with static IP 10.10.10.100"
microstack.openstack server create --flavor m1.tiny --image cirros --key-name keyManh --security-group default --nic port-id=$port_id VM2

# Chờ cho đến khi VM2 ở trạng thái "ACTIVE"
echo "Waiting for VM2 to become ACTIVE..."
status_vm2=$(microstack.openstack server show VM2 -f value -c status)
while [ "$status_vm2" != "ACTIVE" ]; do
  echo "VM2 is in status: $status_vm2. Waiting..."
  sleep 5
  status_vm2=$(microstack.openstack server show VM2 -f value -c status)
done
echo "VM2 is ACTIVE. Proceeding with Floating IP assignment."

# Tạo và gán Floating IP cho VM2, chỉ định địa chỉ IP cụ thể do VM2 có nhiều IP
echo "Creating Floating IP for VM2"
floating_ip_id_vm2=$(microstack.openstack floating ip create external -f value -c id)
floating_ip_vm2=$(microstack.openstack floating ip show $floating_ip_id_vm2 -f value -c floating_ip_address)
echo "Floating IP for VM2: $floating_ip_vm2"

echo "Assigning Floating IP to VM2"
microstack.openstack floating ip set --port $port_id --fixed-ip-address 10.10.10.100 $floating_ip_id_vm2

# Kiểm tra và liệt kê các Floating IP và server đã tạo
echo "Listing floating IPs : microstack.openstack floating ip list"
microstack.openstack floating ip list

echo "Listing servers : microstack.openstack server list"
microstack.openstack server list

echo "microstack.openstack router set --external-gateway external Router1"
microstack.openstack router set --external-gateway external Router1

echo "sudo sysctl -w net.ipv4.ip_forward=1"
sudo sysctl -w net.ipv4.ip_forward=1

echo "sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE"
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

echo "Setup completed successfully."
echo "ssh -i keyManh.pem cirros@$floating_ip_vm2"





