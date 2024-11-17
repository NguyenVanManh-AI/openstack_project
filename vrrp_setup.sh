#!/bin/bash

HOSTNAME=$(hostname)

# Kiểm tra hostname để xác định trạng thái VRRP
if [ "$HOSTNAME" == "vrrp-master" ]; then
    KEEPALIVED_STATE='MASTER'
    KEEPALIVED_PRIORITY=100
elif [ "$HOSTNAME" == "vrrp-slave" ]; then  # Đổi từ "vrrp-backup" thành "vrrp-slave"
    KEEPALIVED_STATE='BACKUP'
    KEEPALIVED_PRIORITY=50
else
    echo "invalid hostname $HOSTNAME for install script $0";
    exit 1;
fi

# Lấy IP của máy và thêm vào /etc/hosts
IP=$(ip addr | grep inet | grep ens3 | grep -v secondary | awk '{ print $2 }' | awk -F'/' '{ print $1 }')
echo "$IP $HOSTNAME" >> /etc/hosts

# Cập nhật và cài đặt keepalived
apt-get update
apt-get -y install keepalived

# Cấu hình Keepalived với các thông số đã xác định
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

# Cài đặt Apache2 và cấu hình trang web mặc định
apt-get -y install apache2
echo "$HOSTNAME" > /var/www/html/index.html

# Mở cổng 80 cho HTTP trên tường lửa
echo "Mở cổng HTTP trên tường lửa..."
sudo ufw allow 80/tcp
sudo ufw reload

# Đảm bảo Apache2 đang chạy
echo "Khởi động lại Apache2..."
sudo systemctl restart apache2
sudo systemctl enable apache2

# Cấu hình lại iptables để NAT và chuyển tiếp lưu lượng từ Floating IP
echo "Cấu hình NAT và chuyển tiếp lưu lượng..."
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i ens3 -o ens33 -j ACCEPT

# Đảm bảo rằng IP forwarding đã được bật
echo "Bật IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1

# Khởi động lại Keepalived để áp dụng cấu hình
echo "Khởi động lại Keepalived..."
service keepalived restart

# Kiểm tra trạng thái của Keepalived và Apache2
echo "Kiểm tra trạng thái dịch vụ..."
sudo systemctl status keepalived
sudo systemctl status apache2

# Thông báo về các địa chỉ IP
echo "Virtual IP của bạn là: 10.10.10.200"
echo "Trang web có thể truy cập tại: http://$IP"
