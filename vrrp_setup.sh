#!/bin/bash

# Lấy tên máy để xác định vai trò trong VRRP
HOSTNAME=$(hostname)

# Xác định trạng thái Keepalived dựa trên tên máy
if [ "$HOSTNAME" == "vrrp-master" ]; then
    KEEPALIVED_STATE='MASTER'
    KEEPALIVED_PRIORITY=100
elif [ "$HOSTNAME" == "vrrp-slave" ]; then
    KEEPALIVED_STATE='BACKUP'
    KEEPALIVED_PRIORITY=50
else
    echo "invalid hostname $HOSTNAME for install script $0";
    exit 1;
fi

# Lấy địa chỉ IP thực của máy
IP=$(ip addr | grep inet | grep ens3 | grep -v secondary | awk '{ print $2 }' | awk -F'/' '{ print $1 }')

# Cập nhật IP thực của máy vào /etc/hosts
echo "$IP $HOSTNAME" >> /etc/hosts

# Cài đặt Keepalived
apt-get update
apt-get -y install keepalived

# Cấu hình Keepalived với địa chỉ IP floating của bạn
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
        10.20.20.X/24 brd 10.20.20.255 dev ens3
    }
}" > /etc/keepalived/keepalived.conf

# Cài đặt Apache2 và cấu hình trang web mặc định
apt-get -y install apache2
echo "$HOSTNAME" > /var/www/html/index.html

# Mở cổng 80 cho HTTP trên tường lửa
ufw allow 80/tcp
ufw reload

# Khởi động lại Apache2
systemctl restart apache2
systemctl enable apache2

# Khởi động lại Keepalived để áp dụng cấu hình
service keepalived restart

# Kiểm tra trạng thái của Keepalived và Apache2
systemctl status keepalived
systemctl status apache2

# Thông báo về các địa chỉ IP
echo "Virtual IP của bạn là: 10.20.20.X"
echo "Trang web có thể truy cập tại: http://$IP"
