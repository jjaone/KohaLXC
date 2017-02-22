#!/bin/bash

#
# Name: lxc.hook.xyz-abc
# Desc: A hook script that is invoked by container config w/
# - $1 = CN
# - $2 = Section ('lx')
# - $3 = hook-type
# - $* = Additional args
# LXC_NAME = CN
# LXC_ROOTFS_MOUNT = where container rootfs is mounted
# LXC_CONFIG_FILE = container config file
#
# Source: https://www.stgraber.org/2013/12/23/lxc-1-0-some-more-advanced-container-usage/
#

## Intercept CLI arguments from lxc.network.up and .down -commands
lxc_container_name="$1" # for ex. 'kohademo'
lxc_config_section="$2" #Should be 'net'
lxc_execution_context="$3" #Should be 'up' or 'down'
lxc_network_type="$4" #Should be 'veth|macvlan|phys'
lxc_host_sided_device_name="$5"
echo $lxc_container_name

##
# TODO: This does not work:
# - on start it gets called but container does not start
# - /tmp does not containe anything
# - nor do the other echos show anything
##
#echo $LXC_NAME

echo "arguments: $*" > /tmp/lxchook-test
echo "environment:" >> /tmp/lxchook-test
env | grep LXC >> /tmp/lxchook-test

exit 0
