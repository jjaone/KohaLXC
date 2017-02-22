#!/bin/bash

#
# Name: lxcnet_updown-debug_script.sh
# Desc: A LXC-networking debug script invoked by container config..
# using 'lxc.network.script.up/down' -option (if set) that sets here:
# - $1 = CN
# - $2 = Section ('lxc')
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

echo && echo "== ================================================================ ==" > /tmp/lxcnet_updown-debug_script
echo "== script:$0 ==" >> /tmp/lxcnet_updown-debug_script
echo "== args: $*" >> /tmp/lxcnet_updown-debug_script
# $1 = $lxc_container_name = $LXC_NAME
echo "== lxc_container_name=$lxc_container_name" >> /tmp/lxcnet_updown-debug_script
# $2 = $lxc_config_section 
echo "== lxc_config_section=$lxc_config_section" >> /tmp/lxcnet_updown-debug_script
# $3 = $lxc_execution_context 
echo "== lxc_execution_context=$lxc_execution_context" >> /tmp/lxcnet_updown-debug_script
# $4 = $lxc_network_type 
echo "== lxc_network_type=$lxc_network_type" >> /tmp/lxcnet_updown-debug_script
# $5 = $lxc_host_sided_device_name = V+CN
echo "== lxc_host_sided_device_name=$lxc_host_sided_device_name" >> /tmp/lxcnet_updown-debug_script

# Env:
echo "== Environment:" >> /tmp/lxcnet_updown-debug_script
# whoami: "root"
whoami >> /tmp/lxcnet_updown-debug_script
# pwd: "/"
pwd >> /tmp/lxcnet_updown-debug_script
# env:
env | grep LXC >> /tmp/lxcnet_updown-debug_script

echo && echo "== ============================================================= ==" >> /tmp/lxcnet_updown-debug_script
# Outbound IP
outbound_ip=`ifconfig | grep -P -A1 '^bond0 ' | grep -Po '\sinet addr:\d+\.\d+\.\d+\.\d+\s' | grep -Po '\d+\.\d+\.\d+\.\d+'`
echo "== outbound_ip=$outbound_ip" >> /tmp/lxcnet_updown-debug_script

echo "== Contents of: /var/lib/lxc/$lxc_container_name/rootfs/etc/network/interfaces" >> /tmp/lxcnet_updown-debug_script
cat /var/lib/lxc/$lxc_container_name/rootfs/etc/network/interfaces >> /tmp/lxcnet_updown-debug_script

# Find the lxc_container ip by grep:ing the config-file for lxc.networking.ipv4 = *.*.*.*
lxc_container_manual_ip=`grep -P 'lxc.network.ipv4 = \d+\.\d+\.\d+\.\d+' /var/lib/lxc/$lxc_container_name/config | grep -Po '\d+\.\d+\.\d+\.\d+'`
echo "== (from manual LXC-config) lxc_container_manual_ip=$lxc_container_manual_ip" >> /tmp/lxcnet_updown-debug_script

# Find the lxc ip by grepping the  dhcp-lease file for  lxc_container_name line
echo "== Contents of: /var/lib/misc/dnsmasq.lxcbr0.leases" >> /tmp/lxcnet_updown-debug_script
cat /var/lib/misc/dnsmasq.lxcbr0.leases >> /tmp/lxcnet_updown-debug_script
lxc_container_dhcp_ip=`grep -P 'weblxc_default' /var/lib/misc/dnsmasq.lxcbr0.leases | cut -d" " -f3`
echo "== (from host-dhcp dnsmaq.lxcbr0.leases) lxc_container_dhcp_ip=$lxc_container_dhcp_ip" >> /tmp/lxcnet_updown-debug_script

# Note: the below prevents LXC from starting.. reboot of host required
#lxc-ls -f >> /tmp/lxcnet_updown-debug_script

echo "== ================================================================== ==" >> /tmp/lxcnet_updown-debug_script
exit 0
