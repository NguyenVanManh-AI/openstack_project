#!/bin/bash

# Xác định tên máy để xác định vai trò trong VRRP
HOSTNAME=$(hostname)

# Xác định trạng thái Keepalived dựa trên tên máy
if [ "$HOSTNAME" == "vrrp-master" ]; then
    KEEPALIVED_STATE='MASTER'
    KEEPALIVED_PRIORITY=100
elif [ "$HOSTNAME" == "vrrp-slave" ]; then
    KEEPALIVED_STATE='BACKUP'
    KEEPALIVED_PRIORITY=50
else
    echo "Invalid hostname $HOSTNAME for install script $0"
    exit 1
fi

# Cài đặt Keepalived và Apache2 nếu chưa cài đặt
apt-get update
apt-get -y install keepalived apache2

# Đảm bảo Apache2 luôn chạy
systemctl enable apache2
systemctl start apache2

# Cấu hình Keepalived với địa chỉ IP floating
echo "vrrp_instance vrrp_group_1 {
    state $KEEPALIVED_STATE
    interface ens3
    virtual_router_id 1
    priority $KEEPALIVED_PRIORITY
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass password
    }
    virtual_ipaddress {
        10.20.20.200/24  # Địa chỉ IP floating
    }
}" > /etc/keepalived/keepalived.conf

# Khởi động lại Keepalived để áp dụng cấu hình
systemctl enable keepalived
service keepalived restart

# Kiểm tra trạng thái Keepalived và Apache2
systemctl status keepalived
systemctl status apache2
