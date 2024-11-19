#!/bin/bash

echo "Starting Reset Microstack"
# Xóa Servers
echo "Deleting all servers..."
microstack.openstack server list -f value -c ID | xargs -I {} microstack.openstack server delete {}

# Xóa Ports
echo "Deleting all ports..."
microstack.openstack port list -f value -c ID | xargs -I {} microstack.openstack port delete {}

# Xóa Routers
echo "Deleting all routers..."
microstack.openstack router list -f value -c ID | xargs -I {} microstack.openstack router delete {}

# Xóa Subnets
echo "Deleting all subnets..."
microstack.openstack subnet list -f value -c ID | xargs -I {} microstack.openstack subnet delete {}

# Xóa Networks
echo "Deleting all networks..."
microstack.openstack network list -f value -c ID | xargs -I {} microstack.openstack network delete {}

# Xóa Keypairs
echo "Deleting all keypairs..."
microstack.openstack keypair list -f value -c Name | xargs -I {} microstack.openstack keypair delete {}

# Xóa Floating IPs
echo "Deleting all Floating IPs..."
microstack.openstack floating ip list -f value -c ID | xargs -I {} microstack.openstack floating ip delete {}

echo "Cleanup completed!"
