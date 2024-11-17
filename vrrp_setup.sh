#!/bin/bash

# Xác định tên máy chủ (hostname)
HOSTNAME=$(hostname)

# Thiết lập trạng thái và ưu tiên của Keepalived
if [ "$HOSTNAME" == "vrrp-master" ]; then
    KEEPALIVED_STATE='MASTER'
    KEEPALIVED_PRIORITY=100
elif [ "$HOSTNAME" == "vrrp-slave" ]; then
    KEEPALIVED_STATE='BACKUP'
    KEEPALIVED_PRIORITY=50
else
    echo "Invalid hostname $HOSTNAME for the setup script $0"
    exit 1
fi

# Lấy địa chỉ IP của giao diện eth0
IP=$(ip addr | grep inet | grep eth0 | awk '{print $2}' | cut -d'/' -f1)

# Thêm địa chỉ IP và hostname vào /etc/hosts
echo "$IP $HOSTNAME" >> /etc/hosts

# Cập nhật và cài đặt các gói cần thiết
apt-get update
apt-get -y install keepalived apache2

# Cấu hình Keepalived
cat <<EOL > /etc/keepalived/keepalived.conf
vrrp_instance vrrp_group_1 {
    state $KEEPALIVED_STATE
    interface eth0
    virtual_router_id 1
    priority $KEEPALIVED_PRIORITY
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass password
    }
    virtual_ipaddress {
        10.10.10.200/24
    }
}
EOL

# Tạo trang web đơn giản để xác minh máy chủ đang hoạt động
echo "$HOSTNAME" > /var/www/html/index.html

# Khởi động lại dịch vụ Keepalived
service keepalived restart

# Kiểm tra trạng thái dịch vụ Keepalived
systemctl status keepalived

echo "Keepalived setup completed for $HOSTNAME"
