#!/bin/bash
#Written by Rafael Sene and Mick Tarsel

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        echo "Bye!"
}

#Keeping everything in build dir
PROJECT_DIR=$(pwd)

# ICP Variables
ICP_LOCATION=/opt/ibm-cloud-private-3-1-0
INCEPTION=ibmcom/icp-inception:3.1.0

# Get the main IP of the host
HOSTNAME_IP=$(ip route get 1 | awk '{print $NF;exit}')
HOSTNAME=$(hostname)

#in case supplied different IP than found, likely never used
if [ -z "$1" ]; then
    EXTERNAL_IP=$HOSTNAME_IP
else
    EXTERNAL_IP=$1
fi

# Create SSH Key and overwrite any already created
yes y | ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""

# Append ssh-key in the authorized_keys
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# Updating, upgrading and installing some packages
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -yq
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -yq vim python git

# Verify file is executable and install Docker
# https://github.com/rpsene/icp-scripts
[ -x $PROJECT_DIR/install_docker.sh ] || chmod +x install_docker.sh
$PROJECT_DIR/install_docker.sh

# Configuring ICP details (as described in the documentation)
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sysctl -w net.ipv4.ip_local_port_range="10240  60999"
echo 'net.ipv4.ip_local_port_range="10240 60999"' | sudo tee -a /etc/sysctl.conf

# Verify what ports are available
# https://github.com/rpsene/icp-scripts
[ -x $PROJECT_DIR/check_ports.py ] || chmod +x check_ports.py
python $PROJECT_DIR/check_ports.py

# Configure network (/etc/hosts)
# This line is required for a OpenStack or PowerVC environment
sed -i -- 's/manage_etc_hosts: true/manage_etc_hosts: false/g' /etc/cloud/cloud.cfg
sed -i '/127.0.1.1/s/^/#/g' /etc/hosts
sed -i '/ip6-localhost/s/^/#/g' /etc/hosts
echo -e "$HOSTNAME_IP $HOSTNAME" | tee -a /etc/hosts

# Disable StrictHostKeyChecking ask
sed -i -- 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config

# Prepare environment for ICP installation
docker pull $INCEPTION
mkdir -p $ICP_LOCATION && cd $ICP_LOCATION || exit
docker run -v "$(pwd)":/data -e LICENSE=accept $INCEPTION cp -r cluster /data
cp /root/.ssh/id_rsa ./cluster/ssh_key

cd ./cluster || exit

# Remove the content of the hosts file
> ./hosts

# Add the IP of the single node in the hosts file
echo "
[master]
$HOSTNAME_IP

[worker]
$HOSTNAME_IP

[proxy]
$HOSTNAME_IP

#[management]
#4.4.4.4

#[va]
#5.5.5.5
" >> ./hosts

# Make sure images are accesible
echo "
image-security-enforcement:
   clusterImagePolicy:
     - name: "docker.io/ibmcom/*"
       policy:
" >> ./config.yaml

# Replace the entries in the config file to remove the comments of the external IPs
sed -i -- "s/# cluster_lb_address: none/cluster_lb_address: $EXTERNAL_IP/g" ./config.yaml
sed -i -- "s/# proxy_lb_address: none/proxy_lb_address: $EXTERNAL_IP/g" ./config.yaml

# Install ICP
docker run --net=host -t -e LICENSE=accept -v "$(pwd)":/installer/cluster $INCEPTION install
