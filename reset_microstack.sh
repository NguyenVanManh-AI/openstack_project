#!/bin/bash

echo "Starting Reset Microstack"
# Xóa tất cả các máy ảo
echo "Deleting all servers..."
SERVERS=$(microstack.openstack server list -f value -c ID)
for server in $SERVERS; do
    microstack.openstack server delete $server
done

# Xóa tất cả các cổng mạng
echo "Deleting all ports..."
PORTS=$(microstack.openstack port list -f value -c ID)
for port in $PORTS; do
    microstack.openstack port delete $port
done

# Xóa tất cả các router và gỡ bỏ kết nối
echo "Deleting all routers..."
ROUTERS=$(microstack.openstack router list -f value -c ID)
for router in $ROUTERS; do
    # Gỡ bỏ kết nối giữa router và các subnet trước khi xóa
    SUBNETS=$(microstack.openstack subnet list -f value -c ID)
    for subnet in $SUBNETS; do
        microstack.openstack router remove subnet $router $subnet
    done
    microstack.openstack router unset --external-gateway $router
    microstack.openstack router delete $router
done

# Xóa tất cả các subnet
echo "Deleting all subnets..."
SUBNETS=$(microstack.openstack subnet list -f value -c ID)
for subnet in $SUBNETS; do
    microstack.openstack subnet delete $subnet
done

# Xóa tất cả các mạng
echo "Deleting all networks..."
NETWORKS=$(microstack.openstack network list -f value -c ID)
for network in $NETWORKS; do
    microstack.openstack network delete $network
done

# Xóa tất cả các keypair
echo "Deleting all keypairs..."
KEYPAIRS=$(microstack.openstack keypair list -f value -c Name)
for keypair in $KEYPAIRS; do
    microstack.openstack keypair delete $keypair
done

# Xóa tất cả các Floating IPs
echo "Deleting all Floating IPs..."
FLOATING_IPS=$(microstack.openstack floating ip list -f value -c "Floating IP Address")
for ip in $FLOATING_IPS; do
    microstack.openstack floating ip delete $ip
done

echo "Cleanup completed!"
