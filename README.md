# ICP-POWER-Up
Install IBM Cloud Private CE using POWER-Up.

# Getting Started

1. Install pup: https://github.com/open-power-ref-design-toolkit/power-up Provide a public IP address to access the ICP dashboard.

2. Create a  configuration file that includes this snippet from the [icp-config.yaml](./icp-config.yaml). Example [config.yaml](./config.yaml)

3. Launch your cluster with ```pup deploy config.yml``` 


**NOTE:** You will have to enter your sudo password once the deploy is started and then hit Enter a few times. This process will take over 1 hour to complete.

The deploy command starts with the installation of some Linux distribution and finishing by executing the [icp-install.sh](./icp-install.sh) and installing IBM Cloud Private-CE version 3.1.0. Make sure your configuration file contains the info from [icp-config.yaml](./icp-config.yaml) in this repo.

## Deploying only software
If you don't want to re-install Linux just run ```pup post-deploy config.yml```


# How it Works

The [config.yaml](./config.yaml) file drives the installation process. Inside this file contains all the switch info and network configurations.

## The config.yml
The [icp-config.yaml](./icp-config.yaml) YAML file in this repo is only a snippet used to deploy a cluster using [config.yaml](./config.yaml).

POWER-Up will identify a single node via the hostname, for our example the hostname is server-1.

This single node will become the ICP Master. The bash script in this repo will be executed on that single ICP Master node.


## Installing IBM Cloud Private CE

ICP is installed via [icp-install.sh](./icp-install.sh) in this repo. 

IBM documentation: https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/installing/install_containers_CE.html

It utilizes 2 files taken from other repos.

See: https://github.com/Unicamp-OpenPower/docker_on_power

and

https://github.com/rpsene/icp-scripts

# Removing and Cleanup

Remove your cluster ```teardown switches --data configuration.yml; teardown deployer --container configuration.yml```
