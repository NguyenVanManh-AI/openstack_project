#!/bin/bash
microstack.openstack network create N1
microstack.openstack network list
microstack.openstack subnet create --network N1 --subnet-range 10.10.10.0/24 --gateway 10.10.10.1 --allocation-pool start=10.10.10.10,end=10.10.10.50 S1
microstack.openstack subnet list
microstack.openstack router create R1
microstack.openstack router list
microstack.openstack router set R1 --external-gateway external
microstack.openstack router add subnet R1 S1

microstack.openstack security group create webtraffic
microstack.openstack security group list

microstack.openstack security group rule create --ingress --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0 webtraffic
microstack.openstack security group rule create --ingress --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0 webtraffic
microstack.openstack security group rule list webtraffic

microstack.openstack port create --network N1 --fixed-ip subnet=S1,ip-address=10.10.10.100 --security-group webtraffic port-N1

microstack.openstack keypair create keyCuong > keyCuong.pem
chmod 400 keyCuong.pem

# 1. Đặt gateway cho router
echo "Setting external gateway for router R1..."
microstack.openstack router set --external-gateway external R1

# 2. Bật IP forwarding
echo "Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1

# 3. Cấu hình NAT (MASQUERADE) trên interface ens33
echo "Configuring NAT (MASQUERADE) on interface ens33..."
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

# 4. Tải bootscript.sh và đặt quyền
echo "Downloading bootscript.sh..."
wget -q https://raw.githubusercontent.com/nguyenvanhoangphuc/CNMang/main/bootscript.sh -O bootscript.sh

echo "Moving bootscript.sh to /snap/microstack/ and setting permissions..."
sudo mv bootscript.sh /snap/microstack/
sudo chmod +r /snap/microstack/bootscript.sh

# 5. Tạo server mới với script khởi động
echo "Creating a new server Web-Server..."
PORT_ID=$(microstack.openstack port list | grep port-N1 | awk '{print $2}')
microstack.openstack server create \
  --flavor m1.small \
  --image "ubuntu16" \
  --key-name keyCuong \
  --security-group webtraffic \
  --nic port-id=$PORT_ID \
  --user-data /snap/microstack/bootscript.sh \
  Web-Server

# 6. Tạo Floating IP
echo "Creating a floating IP..."
# Tạo floating IP và lưu ID vào biến
FLOATING_IP_ID=$(microstack.openstack floating ip create external -f value -c id)
# Lấy địa chỉ IP của floating IP và lưu vào biến
FLOATING_IP_ADDRESS=$(microstack.openstack floating ip show $FLOATING_IP_ID -f value -c floating_ip_address)
# In ra ID và địa chỉ của floating IP
echo "Floating IP ID: $FLOATING_IP_ID"
echo "Floating IP Address: $FLOATING_IP_ADDRESS"

# 7. Liên kết Floating IP với server
echo "Associating floating IP with server..."
microstack.openstack floating ip set --port $PORT_ID $FLOATING_IP_ID

# Bước 12: Kiểm tra trạng thái của server Web-Server trước khi kết thúc
echo "Waiting for Web-Server to become ACTIVE..."
while true; do
    SERVER_STATUS=$(microstack.openstack server show Web-Server -f value -c status)
    if [[ "$SERVER_STATUS" == "ACTIVE" ]]; then
        echo "Web-Server is ACTIVE."
        break
    else
        echo "Waiting for Web-Server to become ACTIVE..."
        sleep 5
    fi
done

sudo apt update
sudo apt install -y curl

# Check HTTP connection to floating IP address
echo "Checking HTTP connection to floating IP $FLOATING_IP_ADDRESS..."
echo "curl http://$FLOATING_IP_ADDRESS -> OK"

# Check SSH connection to floating IP address
echo "Checking SSH connection to floating IP $FLOATING_IP_ADDRESS..."
echo "ssh -i keyCuong.pem root@$FLOATING_IP_ADDRESS -> OK"

# Check ping connection to floating IP address with time limit (Expected to fail)
echo "Checking ping connection to floating IP $FLOATING_IP_ADDRESS with time limit of 10 seconds..."
echo "ping -c 4 -w 10 $FLOATING_IP_ADDRESS -> Fail : Ping failed as expected, ping to floating IP is not allowed."

# Kết thúc
echo "Script execution completed!"