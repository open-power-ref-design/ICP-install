# ICP-POWER-Up
Install ICP via POWER-Up

# Getting Started

Follow instructions on POWER-Up repo to setup pup: https://github.com/open-power-ref-design-toolkit/power-up

Launch your cluster with ```pup deploy config.yml``` making sure your configuration file includes the snippet from the [icp-config.yaml](./icp-config.yaml). 

Provide a public IP address to your master node in order to access the ICP dashboard.

**NOTE:** You will have to enter your sudo password once the deploy is started and then hit Enter a few times. This process will take over 1 hour to complete.

This will run through the entire installation process, starting with the installation of some Linux distribution and finishing by running the [icp-install.sh](./icp-install.sh) and installing ICP. Make sure your configuration file contains the info from [icp-config.yaml](./icp-config.yaml) in this repo.

## Deploying only software
If you don't want to re-install Linux just run ```pup post-deploy config.yml```


# How it Works

The config.yaml file drives the installation process. Inside this file contains all the switch info and network configurations. An example file is included in [config.yaml](./config.yaml).

## The config.yml
The [icp-config.yaml](./icp-config.yaml) YAML file in this repo is only a snippet used to deploy a cluster using [config.yaml](./config.yaml). 

POWER-Up will identify a single node via the hostname, for our example the hostname is server-1.

This single node will become the ICP Master. The bash script in this repo will be executed on that single ICP Master node.


## Installing ICP

ICP is installed via [icp-install.sh](./icp-install.sh) in this repo. It utilizes 2 files taken from other repos.

See: https://github.com/Unicamp-OpenPower/docker_on_power

and

https://github.com/rpsene/icp-scripts

# Removing and Cleanup

Remove your cluster ```teardown switches --data configuration.yml; teardown deployer --container configuration.yml```
