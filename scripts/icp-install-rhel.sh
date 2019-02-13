#!/bin/bash
# Written by Mick Tarsel

# Install IBM Cloud Private CE
# Example how to run
#   chmod +x ./icp-install-rhel.sh; ./icp-install-rhel.sh 3.1.1

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
        echo "Bye!"
}

setup_var_dirs() {
  #First arg of this script is ICP version. 
  #  then create installation directory

  #get ICP version (from pup)
  if [ -z "$1" ]; then
    #argument 1 is a null string so install some version
    ICP_VERSION=3.1.2
  else
    ICP_VERSION=$1
  fi

  #TODO validate ICP version just to make sure we dont pull some rando container
  #if [[ $ICP_VERSION =~ ^(\d+\.)?(\d+\.)?(\d+\$ ]];then
#  if [[ $ICP_VERSION =~ ^[0-9]+\.[0-9]+\. ]];then
#     echo $ICP_VERSION
#  else
#     echo "improper version format!"
#     exit 1
#  fi


  # ICP Variables
  # replace the '.' with '-' in the version
  ICP_LOCATION=/opt/ibm-cloud-private-"${ICP_VERSION//./-}"
  INCEPTION=ibmcom/icp-inception:$ICP_VERSION

  # Get the primary IP of the host
  HOSTNAME_IP=$(ip -o route get 9.9.9.9 | sed -e 's/^.* src \([^ ]*\) .*$/\1/')
  HOSTNAME=$(hostname)

  mkdir -p $ICP_LOCATION

  #TODO: change to $2 in case supplied different IP than found
  #if [ -z "$1" ]; then
  #    EXTERNAL_IP=$HOSTNAME_IP
  #else
  #    EXTERNAL_IP=$1
  #fi
}

manage_ssh_keys(){
  # Create SSH Key and overwrite any already created
  yes y | ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""

  # Append ssh-key in the authorized_keys
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

  # Disable StrictHostKeyChecking ask
  sed -i -- 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config
}

setup_package_repos_rhel(){
  yum update -y
  yum install -y vim python git docker
}

#TODO - this is dependent on customers entitlements!!!
install_docker(){
 setenforce 0 # disable se-linux 
 service docker start
}

configure_port_range(){
  # Configuring ICP details (as described in the documentation)
  sysctl -w vm.max_map_count=262144
  echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
  sysctl -w net.ipv4.ip_local_port_range="10240  60999"
  echo 'net.ipv4.ip_local_port_range="10240 60999"' | sudo tee -a /etc/sysctl.conf

  #TODO disable firewalld?
  service firewalld stop
}

check_ports(){
  # Make sure these ports are open so ICP can use them

  PORTS=( 80, 179, 443, 2222, 2380, 4001, 4194, 4300, 4500, 5000, 5044, 5046, 8001,
  8080, 8082, 8084, 8101, 8181, 8443, 8500, 8600, 8743, 8888, 9200, 9235, 9300,
  9443, 10248, 10249, 10250, 10251, 10252, 18080, 24007, 24008, 35357 )
#PORTS_RANGES=['10248:10252', '30000:32767', '49152:49251']

  # iterate thru ports and remove , seperating the values
  for port in ${PORTS[@]/,/""}; do
    if [ -n "$(ss -tnl | awk '{print $4}'| egrep -w $port)" ]; then
      # if string is non-zero means port is used
      echo "$port in use"
      #get processID of port
      #TODO
      cat /etc/services | grep " $port/"
    fi
  done

  for port in `seq 10248 10252`;do
    if [ -n "$(ss -tnl | awk '{print $4}'| egrep -w $port)" ]; then
      # if string is non-zero means port is used
      echo "$port in use"
      #get processID of port
      cat /etc/services | grep " $port/"
    fi
  done

  for port in `seq 30000 32767`;do
    if [ -n "$(ss -tnl | awk '{print $4}'| egrep -w $port)" ]; then
      # if string is non-zero means port is used
      echo "$port in use"
      #get processID of port
    cat /etc/services | grep " $port/"
    fi
  done

  for port in `seq 49152 49251`;do
    if [ -n "$(ss -tnl | awk '{print $4}'| egrep -w $port)" ]; then
      # if string is non-zero means port is used
      echo "$port in use"
      #get processID of port
        cat /etc/services | grep " $port/"
    fi
  done
}

configure_etc_hosts(){
  # This line is required for a OpenStack or PowerVC environment
  # sed -i -- 's/manage_etc_hosts: true/manage_etc_hosts: false/g' /etc/cloud/cloud.cfg

  # Configure network in /etc/hosts file
  sed -i '/127.0.1.1/s/^/#/g' /etc/hosts
  sed -i '/ip6-localhost/s/^/#/g' /etc/hosts
  echo -e "$HOSTNAME_IP $HOSTNAME" | tee -a /etc/hosts
}

setup_ICP_container(){

  # Turn smt off
  # ppc64_cpu --smt=off

  # Prepare environment for ICP installation by running icp-inception
  docker pull $INCEPTION
  cd $ICP_LOCATION || exit
  docker run -v "$(pwd)":/data -e LICENSE=accept $INCEPTION cp -r cluster /data
  cp /root/.ssh/id_rsa ./cluster/ssh_key
}

setup_hosts_file(){
  # Remove the contents of the hosts file
  > $ICP_LOCATION/cluster/hosts

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
  " >> $ICP_LOCATION/cluster/hosts
}

install_ICP(){
  #first cd into cluser since docker run uses pwd
  cd $ICP_LOCATION/cluster/ || exit

  # Replace the entries in the config file to remove the comments of the external IPs
  sed -i -- "s/# cluster_lb_address: none/cluster_lb_address: $EXTERNAL_IP/g" ./config.yaml
  sed -i -- "s/# proxy_lb_address: none/proxy_lb_address: $EXTERNAL_IP/g" ./config.yaml

  # Create admin password
  PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)
  sed -i -- "s/# default_admin_password:/default_admin_password: $PASSWORD/g" ./config.yaml

  # Validating the configuration
  # docker run -e LICENSE=accept --net=host -v “$(pwd)“:/installer/cluster $INCEPTION check | tee –a check.log

  # Install ICP
  docker run --net=host -t -e LICENSE=accept -v "$(pwd)":/installer/cluster $INCEPTION install

}

#####=================#####
##### BEGIN EXECUTION #####
#####=================#####

echo "Starting installation of ICP"
setup_vars_dirs

echo "Creating new ssh keys..."
manage_ssh_keys

echo "Installing packages..."
setup_package_repos_rhel

echo "Starting docker..."
install_docker

echo "Configuring port ranges..."
configure_port_range

#echo "Checking available ports...."
#check_ports

echo "Configuring /etc/hosts file..."
configure_etc_hosts

echo "Pulling ICP CE container..."
setup_ICP_container

echo "Setting up $ICP_LOCATION/cluster/hosts file..."
setup_hosts_file

echo "Installing ICP CE..."
install_ICP

