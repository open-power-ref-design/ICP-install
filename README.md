# ICP-POWER-Up
Install ICP via POWER-Up

# Instructions

Follow instructions on POWER-Up repo: https://github.com/open-power-ref-design-toolkit/power-up

Provide a public IP address to our master node in order to access the ICP dashboard.

Launch your cluster with ```pup deploy configuration.yml``` making sure your configuration.yml includes the snippet from the [icp-config.yaml](./icp-config.yaml). 

NOTE: You will have to enter your sudo password once the deploy is started and then hit Enter a few times. This process will take over 1 hour to complete.

This will run through the entire installation process, starting with the installation of some Linux distribution and finishing by running the [icp-install.sh](./icp-install.sh) and installing ICP. Make sure your configuration file contains the info from [icp-config.yaml](./icp-config.yaml) in this repo.


Deploy only software on nodes: ```pup post-deploy configuration.yml```


# How it Works
The YAML file in this repo is only a snippet used to deploy a cluster. Add the [icp-config.yaml](./icp-config.yaml) section in this repo to the bottom of your actual config script.

POWER-Up will identify a single node via the hostname, for our example the hostname is server-1.

This single node will become the ICP Master. The bash script in this repo will be executed on that single ICP Master node.


# Installing ICP

ICP is installed via [icp-install.sh](./icp-install.sh) in this repo. It utilizes 2 files taken from other repos.

See: https://github.com/Unicamp-OpenPower/docker_on_power

and

https://github.com/rpsene/icp-scripts

# Removing and Cleanup

Remove your cluster ```teardown switches --data configuration.yml; teardown deployer --container configuration.yml```
