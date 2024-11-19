#!/bin/bash

echo "Starting Reset Microstack"
# Xóa Servers
echo "Deleting all servers..."
openstack server list --all-projects -f value -c ID | xargs -I {} openstack server delete {}

# Xóa Ports
echo "Deleting all ports..."
openstack port list --all-projects -f value -c ID | xargs -I {} openstack port delete {}

# Xóa Routers
echo "Deleting all routers..."
openstack router list --all-projects -f value -c ID | xargs -I {} openstack router delete {}

# Xóa Subnets
echo "Deleting all subnets..."
openstack subnet list --all-projects -f value -c ID | xargs -I {} openstack subnet delete {}

# Xóa Networks
echo "Deleting all networks..."
openstack network list --all-projects -f value -c ID | xargs -I {} openstack network delete {}

# Xóa Keypairs
echo "Deleting all keypairs..."
openstack keypair list -f value -c Name | xargs -I {} openstack keypair delete {}

# Xóa Floating IPs
echo "Deleting all Floating IPs..."
openstack floating ip list -f value -c ID | xargs -I {} openstack floating ip delete {}

echo "Cleanup completed!"
