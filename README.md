# ICP-POWER-Up
Install IBM Cloud Private 3.1.0 CE using POWER-Up (pup).

# Getting Started

1. Install pup: https://github.com/open-power-ref-design-toolkit/power-up Provide a public IP address to access the ICP dashboard.

2. Create a  configuration file that includes this snippet from the [icp-config.yaml](./yamls/icp-config.yaml). Example [config.yaml](./yamls/config.yaml)

<! -- 3. Launch your cluster with ```pup deploy config.yml``` --> 
3. Launch your cluster with ```pup deploy --extra-vars 'icp-version=3.1.1' config.yml``` 


**NOTE:** You will have to enter your sudo password once the deploy is started and then hit Enter a few times. This process will take over 1 hour to complete.

The deploy command starts with the installation of some Linux distribution and finishing by either executing a bash script, or just simply installing a package (based on your distribution). Make sure your configuration file contains the info from [icp-config.yaml](./yamls/icp-config.yaml) in this repo.

## Deploying only software
If you don't want to re-install Linux just run ```pup post-deploy config.yml```


# How it Works

The [config.yaml](./yamls/config.yaml) file drives pup's (POWER-Up) installation process. Inside this file contains all the switch info and network configurations.

## The config.yml
The [icp-config.yaml](./yamls/icp-config.yaml) YAML file in this repo is only a snippet used to deploy a cluster using [config.yaml](./yamls/config.yaml).

POWER-Up will identify a single node via the hostname, for our example the hostname is server-1.

This single node will become the ICP Master. The bash script in this repo will be executed on that single ICP Master node.


## Installing IBM Cloud Private CE

To install ICP using pup, we download the bash script for the distribution of linux we are running (Ubuntu or RHEL). Then after the OS is installed on our clients, we run the bash scripts. 

### **_This repo is responsible for installing Docker._**

### Ubuntu

ICP is installed via [icp-install-debian.sh](./scripts/icp-install-debian.sh) in this repo. 

IBM documentation: https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/installing/install_containers_CE.html

We also download and [install_docker.sh](./scripts/install_docker.sh) via the script in this repo.

The Ubuntu install utilizes 2 files taken from other repos.

See: https://github.com/Unicamp-OpenPower/docker_on_power

and

https://github.com/rpsene/icp-scripts

### Red Hat Enterprise Linux

First you will have to enter your subscription manager information into your config.yaml in order to install Docker for RHEL. 

To install Docker on Red Hat Enterprise Linux 7 it is necessary to enable the repository ```rhel-7-server-extras-rpms```. To enable this repository via the command line you would run the following command:``` subscription-manager repos --enable rhel-7-server-extras-rpms```. 

Since pup is handling the installation of RHEL and installing Docker and ICP, you will not run this command but rather put your subscription-manager creditentials into your config.yaml like so:

```
node_templates:
    - ...
      os:
          hostname_prefix:
          profile:
          install_device:
          redhat_subscription:
              state: present
              username: joe_user
              password: somepass
              pool_ids:
                - 0123456789abcdef0123456789abcdef
                - 1123456789abcdef0123456789abcdef
          users:
              - name:
                password:
          groups:
              - name:
          kernel_options:
```

ICP is then installed via [icp-install-rhel.sh](./scripts/icp-install-rhel.sh) in this repo. 

# Removing and Cleanup

Remove your cluster ```teardown switches --data configuration.yml; teardown deployer --container configuration.yml```
