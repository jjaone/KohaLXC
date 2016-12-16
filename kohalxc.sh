#!/bin/bash

# File: $KOHALXC_ROOTDIR/kohalxc.sh
# #############################################################################
# Code is part of KohaLXC/kohatools Ansible/Bash tooling scripts environment
# for Koha/ILS-development, deployment & database conversion/migration tasks.
# Author: Jukka Aaltonen, Koha-Lappi, Rovaniemi City Library, Lapland/Finland.
# License: Gnu General Public License version 3.
#
# Description:
# KohaLXC-script (kohalxc.sh) to manage Koha-lxc, configs and setup- tools:
# - utilities to configure, create, start/stop, destroy and use Koha-LXC/hosts
#
# Created: 2016-07-20 by "roikohadev" (@jjaone)
# History:
# #############################################################################

## Script/application/logging
app="kohalxc"
# logfile
logfile="$app.log"
# logdir
logdir="${KOHALXC_ROOTDIR}/log"
# make log dir and file
mkdir -p $logdir && log=$logdir/$logfile && touch $log

## Are we an LXC-container or host?
islxc=0 # 0 = host, 1 = lxc

## source our own and 'kohatools' configurations, tools and common functions
if [[ -f $KOHALXC_ROOTDIR/kohalxc.conf ]]; then
    source $KOHALXC_ROOTDIR/kohalxc.conf
    if [[ ! "$?" -eq 0 ]]; then
	echo "== Failed sourcing: $KOHALXC_ROOTDIR/kohalxc.conf"
	exit 1
    fi
else
    echo "== File not found: ${KOHALXC_ROOTDIR}/kohalxc.conf"
    exit 2
fi

## Exec to redirect all of stdout/stderr to file (and to screen)..
exec &> >(tee -a $log)
echo
echo "== ================================================================== =="
echo "== @$host: $date:"
echo "== $0 '$@'"
echo "== logging to logfile: $log"
echo "== ================================================================== =="


###############################################################################
# Script functions for LXC operations
# - _usage: How to use this script
# - kohalxc_info: Basic info about the KOHALXc-env and LXC (if specified)
###############################################################################

## KOHALXC: this script usage
function _usage {
    ecd "Usage:" "\"$app -f -v [-n CN ] [ansible|init|create|remove|start|attach|console|ssh|stop|destroy]\""
}


## KOHALXC: info about the env
function kohalxc_info {

    # Get the list of all LXC-containers that have been configured
    # - see also in Ansible the variable 'kohahosts_lxcs'
    [[ -d ${KOHALXC_SETUPDIR} ]] &&
	KOHALXC_LXCS="$(/bin/ls -1AB ${KOHALXC_SETUPDIR})"
    KOHALXC_ANSIBLE_LXCS=$KOHALXC_LXCS

    ## General KOHALXC-setup: directories etc..
    [[ -n "$VERBOSE" ]] && \
	(ecd "Environment for KOHALXC_TOOLS/SETUP:";
	 ech "KOHALXC_RC:" "$KOHALXC_RC";
	 ech "KOHALXC_WORKS:" "$KOHALXC_WORKS";
	 ecd "KOHALXC_ORGANIZATION:" "$KOHALXC_ORGANIZATION";
	 ech "KOHALXC_ROOTDIR:" "$KOHALXC_ROOTDIR";
	 ech "KOHALXC_TOOLDIR:" "$KOHALXC_TOOLDIR";
	 ech "KOHALXC_SETUPDIR_BACKUP" "$KOHALXC_SETUPDIR_BACKUP";
	 ech "KOHALXC_SETUPDIR:" "$KOHALXC_SETUPDIR:" &&
	     # If no container set or no container setup dir exists..
	     if [[ -z "$KOHALXC_NAME" ||
			 ! -d "$KOHALXC_SETUPDIR/$KOHALXC_NAME" ]]; then
		 # List and show all the LXC-containers we have in setup-dir.
		 echo -e "$KOHALXC_LXCS" | tr '\n' '\n' | colortab
	     fi
   	)

    ## Container-specific setup (or defults if no KOHALXC_NAME given)
    [[ -n "$VERBOSE" ]] &&
	( ech "Settings for KOHALXC_NAME" \
		      "${KOHALXC_NAME:-(default)}:";
	  # KOHALXC container name and it's setup folder (if any)
	  ecd "KOHALXC_SETUP:" "${KOHALXC_SETUP:-(not set)}" &&
	      [[ -d "$KOHALXC_SETUP" ]] && 
	      (ls -lAB --color=auto $KOHALXC_SETUP | colortab) ||
		  (ece "No container setup in:" \
		       "${KOHALXC_SETUP:-$KOHALXC_SETUPDIR}")
	  ecd "KOHALXC_INFO:" "$KOHALXC_INFO";
	  ecd "KOHALXC_DISTRO:" "$KOHALXC_DISTRO";
	  ecd "KOHALXC_RELEASE:" "$KOHALXC_RELEASE";
	  ecd "KOHALXC_VARIANT:" "$KOHALXC_VARIANT";
	  ecd "KOHALXC_PACKAGES:" "$KOHALXC_PACKAGES";
	)

    # Configuration for '$KOHALXC_NAME' (or for 'default'')
    [[ -n "$VERBOSE" ]] &&
	( echo && [[ -d "$KOHALXC_SETUP_CONFIGDIR" ]] &&
		ech "KOHALXC_SETUP_CONFIGDIR/KOHALXC_CONFIGFILE:" \
		    "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE:";
	  # Contents of initial container configuration (if any)
	  [[ -e "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE" ]] &&
	      (head -24 $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE | colortab) ||
		  (ece "No initial KOHALXC-setup for:" \
		       "'${KOHALXC_NAME:-(default)}' in ${KOHALXC_SETUPDIR}" &&
			  return 1) && echo
	  
	  [[ -d "$KOHALXC_SETUP_CONFIGDIR" ]] &&
	      ech "KOHALXC_SETUP_LXCCONFIG" \
		  "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG:";
	  # Contents of generated LXC-setup (if any)
	  [[ -e "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG" ]] &&
	      (head -10 $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG | colortab) ||
		  (ece "No LXC-configuration '$KOHALXC_LXCCONFIG' for:" \
		       "'${KOHALXC_NAME:-(default)}' in ${KOHALXC_SETUPDIR}" &&
			  return 1)
	)
    
    ## Directory path and list of LXC-containers in /var/lib/lxc (if any)
    [[ -n "$VERBOSE" ]] &&
	( echo && ech "KOHALXC_LXCPATH:" "$KOHALXC_LXCPATH";
	  [[ -n "$KOHALXC_LXCPATH" ]] && sudo test -d $KOHALXC_LXCPATH &&
	      sudo ls -AB $KOHALXC_LXCPATH | grep -v 'lost+found' | colortab
	)

    ## Contents of specified LXC-container in /var/lib/lxc/CN (if any)
    [[ -n "$KOHALXC_LXCPATH" && -n "$KOHALXC_NAME" ]] &&
	sudo test -d $KOHALXC_LXCPATH/$KOHALXC_NAME &&
	echo && ech "Contents of" "$KOHALXC_LXCPATH/$KOHALXC_NAME:" &&
	sudo ls -lAB $KOHALXC_LXCPATH/$KOHALXC_NAME | colortab && echo &&
	ech "Contents of" "$KOHALXC_LXCPATH/$KOHALXC_NAME/config:" &&
	sudo cat $KOHALXC_LXCPATH/$KOHALXC_NAME/config | \
	    grep -v "#" | grep . | colortab

    ## Status/info about the container: (by command 'lxc-info')
    [[ -n "$KOHALXC_NAME" ]] &&
	sudo lxc-ls -f | grep -sq "^$KOHALXC_NAME " ||
	    (ece "LXC given in: '$KOHALXC_NAME' is not current/active" &&
		    return 1) &&
	echo && ecd "LXC-info of" "$KOHALXC_NAME" &&
	sudo lxc-info -n ${KOHALXC_NAME} | colortab &&
	sudo lxc-info -n ${KOHALXC_NAME} -c lxc.group | tr "\n" " " | colortab

    ## List of active/stopped/freezed/cloned containers in the host
    echo && ech "List all containers:" "sudo lxc-ls -f" 
    sudo lxc-ls -f | colortab
    
    ## List of iptables rules in the host
    echo && ech "List iptables rules:" "sudo iptables -L -v -n --line-numbers -t nat"
    sudo iptables -L -v -n --line-numbers -t nat | colortab

    #ecd "Done."
}


## KOHALXC: Manage and run ansible playbooks
function kohalxc_ansible {
    [[ -n "$@" ]] && KOHALXC_ANSIBLE_CMDOPTS="${KOHALXC_ANSIBLE_CMDOPTS} $@"
    [[ -n "$VERBOSE" ]] && (
	ech "KOHALXC_ANSIBLE_ROOTDIR" "$KOHALXC_ANSIBLE_ROOTDIR"
	ech "KOHALXC_ANSIBLE_PLAYBOOKS" "$KOHALXC_ANSIBLE_PLAYBOOKS"
	ech "KOHALXC_ANSIBLE_PLAYBOOK" "$KOHALXC_ANSIBLE_PLAYBOOK"
	ech "KOHALXC_ANSIBLE_INVENTORY" "$KOHALXC_ANSIBLE_INVENTORY"
	ech "KOHALXC_ANSIBLE_CMDOPTS" "$KOHALXC_ANSIBLE_CMDOPTS"
	ech "KOHALXC_ANSIBLE_LXCS" "$KOHALXC_ANSIBLE_LXCS"
    )

    # Set the env for ansible logging
    KOHALXC_ANSIBLE_LOGPATH="$KOHALXC_ANSIBLE_PLAYBOOKS/log/${KOHALXC_ANSIBLE_INVENTORY}.log"
    mkdir -p $(dirname $KOHALXC_ANSIBLE_LOGPATH) &&
	touch $KOHALXC_ANSIBLE_LOGPATH
    ech "KOHALXC_ANSIBLE_LOGPATH:" "$KOHALXC_ANSIBLE_LOGPATH"

    # Build the ansible command for playbook runs
    KOHALXC_ANSIBLE_CMD="ansible-playbook ${KOHALXC_ANSIBLE_PLAYBOOK:-play-all.yaml}  -i ${KOHALXC_ANSIBLE_INVENTORY} ${KOHALXC_ANSIBLE_CMDOPTS:-\"-vvv\"}"
    ech "Running KOHALXC_ANSIBLE_CMD:" "\n$KOHALXC_ANSIBLE_CMD"
    # Ansible playbook default run with specified options
    ( cd $KOHALXC_ANSIBLE_PLAYBOOKS;
      [[ -f $KOHALXC_ANSIBLE_PLAYBOOK ]] &&
	  export KOHALXC_ANSIBLE_LOGPATH &&
	  /usr/local/bin/ansible-playbook \
	      ${KOHALXC_ANSIBLE_PLAYBOOK} \
	      -i ${KOHALXC_ANSIBLE_INVENTORY} \
	      ${KOHALXC_ANSIBLE_CMDOPTS:-"-vvv"} ||
	      ece "Warn ($?)" \
		  "Ansible play '$KOHALXC_ANSIBLE_PLAYBOOK' in [${KOHALXC_ANSIBLE_INVENTORY}] returned error code."
    )
}


## KOHALXC: Initialize env and configure a new container
function kohalxc_init {
    # _init will log to KOHALXC-script log, cause the container is not setup yet
    #ecd "log:" "$log" #= "$KOHALXC_ROOTDIR/log/$app.log"
    mkdir -p $KOHALXC_SETUP | sed 's/^/\t/'
    ecd "Initialize/setup '$KOHALXC_NAME':" "$KOHALXC_SETUP"
    mkdir -p $KOHALXC_SETUP_CONFIGDIR | sed 's/^/\t/'
    ecd "Config in:" "$KOHALXC_SETUP_CONFIGDIR"
    #[[ $verbose -ne 0 ]] && kohalxc_info

    ## Generate initial (default) config
    [[ ! -f $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE ]] &&
		  ecd "No intial config in:" "$KOHALXC_SETUP_CONFIGDIR" &&
		  ecd "Generating:" "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE" &&
        cat <<EOF > $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE
#/bin/bash

##############################################################################
## KOHALXC: main setup/init for KohaSuomi (KohaLappi/LXC)
## KOHALXC_TOOLS/SETUP: $KOHALXC_ROOTDIR ($KOHALXC_SCRIPT)
##############################################################################
#
# Description:    $KOHALXC_INFO
# LXC Name:       $KOHALXC_NAME
# LXC variant:    $KOHALXC_VARIANT
# Ubuntu distro:  $KOHALXC_DISTRO
# Ubuntu release: $KOHALXC_RELEASE
# KOHALXC-config: $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE
# LXC-config:     $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG
# LXC--rcconfig:  $KOHALXC_SETUP_CONFIGDIR/config
# LXC-opts:       --packages $KOHALXC_PACKAGES
# LXC-opts:       --auth-key $KOHALXC_SSHKEY
# LXC-loglevel:   $KOHALXC_SETUP_LOGLEVEL
# LXC-logfile:    $KOHALXC_SETUP_LOGFILE
# Organization:   $KOHALXC_ORGANIZATION
# Developer:      "${KOHALXC_AUTHOR:-Developer}" (${KOHALXC_GITUSER:-anonymous})
# Created:        $KOHALXC_CREATED - Initial  version
# History:        2016-mm-dd - [Summary]

## Settings (KohaLXC tool env)
export KOHALXC_NAME="$KOHALXC_NAME"
export KOHALXC_GROUPS=kohalxcs
export KOHALXC_RELEASE="${KOHALXC_RELEASE:-xenial}"

export KOHALXC_PACKAGES=$KOHALXC_PACKAGES
export KOHALXC_AUTOSTART=0
export KOHALXC_ROOTFS="rootfs"
export KOHALXC_FSTAB="fstab"
export KOHALXC_IPTABLES="iptables.sh"

export KOHALXC_SETUPDIR=$KOHALXC_SETUPDIR
export KOHALXC_SETUPDIR_BACKUP=$KOHALXC_SETUPDIR_BACKUP
export KOHALXC_SETUP=$KOHALXC_SETUP
export KOHALXC_SETUP_CONFIGDIR=$KOHALXC_SETUP/$KOHALXC_CONFIGDIR
export KOHALXC_SETUP_LOGLEVEL=$KOHALXC_SETUP_LOGLEVEL
export KOHALXC_SETUP_LOGDIR=$KOHALXC_SETUP/logs
export KOHALXC_SETUP_LOGFILE=$KOHALXC_SETUP_LOGDIR/$KOHALXC_NAME.log

export KOHALXC_WORKDIR="$HOME/Works/$KOHALXC_NAME"
export KOHALXC_SSHKEY="$HOME/.ssh/id_rsa.pub"

export KOHALXC_SERVER_SSHUSER="${KOHALXC_SERVER_SSHUSER:-$KOHALXC_GITUSER}"
export KOHALXC_SERVER_SSHCMD="${KOHALXC_SERVER_SSHCMD:-uname -a}"
export KOHALXC_SERVER_KOHALXC=$KOHALXC_SERVER_KOHALXC
export KOHALXC_SERVER_KOHATOOLS=$KOHALXC_SERVER_KOHATOOLS
#export KOHALXC_SERVER_KOHACONFIG=$KOHALXC_SERVER_KOHACONFIG
#export KOHALXC_SERVER_KOHASETUP=$KOHALXC_SERVER_KOHASETUP

export KOHALXC_LXCPATH=${KOHALXC_LXCPATH:-/var/lib/lxc}
export KOHALXC_LXCNAME=${KOHALXC_LXCPATH:-/var/lib/lxc}/${KOHALXC_NAME}

### end of file: $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE.
##############################################################################
EOF
    ecd "Initial setup in:" "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE:"
    [[ $verbose -ne 0 ]] &&
	head -44 $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE | colortab && echo

    # Source initial KOHALXC-settings for this LXC
    source $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE
    [[ $verbose -ne 0 ]] &&
	ecd "Sourced KOHALXC environment from generated config file:" &&
	env | grep "KOHALXC_" | colortab

    # Show/create LXC-logging directory/file
    [[ ! -f "$KOHALXC_SETUP_LOGFILE" ]] &&
	echo && ecd "Initialize logging in:" "$KOHALXC_SETUP_LOGDIR .." &&
	mkdir -p $VERBOSE $KOHALXC_SETUP_LOGDIR | colortab &&
	touch $KOHALXC_SETUP_LOGDIR/$KOHALXC_NAME.log

    [[ $verbose -ne 0 ]] &&
	echo && ech "Contents of" "$KOHALXC_SETUP:" &&
	ls -lABR $KOHALXC_SETUP | colortab && echo

    # Show the containers LXC-config (if any)..
    [[ -f $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG ]] &&
	ech "LXC-config exists in " \
	    "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG:" &&
	cat $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG | colortab && return;

    ech "No LXC-config '$KOHALXC_LXCCONFIG' for '$KOHALXC_NAME' in" "$KOHALXC_SETUP_CONFIGDIR"
    read -p "== $app [init] Check/edit '$KOHALXC_CONFIGFILE' (y/n)? " choice
    case "$choice" in
    	y|Y ) ecd "'yes' ==> Come back when happy..bye for now!"; return;;
    	n|N ) ecd "'no' ==> Continuing with initialization..";;
    	* ) ecd "Response invalid..exiting."; return;;
    esac

    ech "Configure in" "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG"

    cat <<EOF > $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG
######################################################################
# LXC-configuration for '$KOHALXC_NAME' 
# (system lxc-cmds e.g. 'lxc-create' and lxc-start can use this)
# Source: $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE
# Config: $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG
# LXC-dir: $KOHALXC_LXCPATH
# Target/name: $KOHALXC_LXCNAME
# Date: $KOHALXC_CREATED by '$KOHALXC_GITUSER'
# Modified:
######################################################################

###########################################
## General: groups,rootfs, fstab, mounts,.. 
###########################################
# TODO: Start on boot
#lxc.start.auto = $KOHALXC_AUTOSTART
lxc.start.auto = $KOHALXC_AUTOSTART

# TODO: container name (do not set, defaults are ok)
#lxc.utsname = $KOHALXC_NAME
#lxc.utsname = $KOHALXC_NAME

# TODO: groups that this container is in
# - need this for automatic deployment/creation tools (e.g. Ansible)
#lxc.group = kohalxcs
#lxc.group = mdblxc
#lxc.group = $KOHALXC_GROUPS
lxc.group = $KOHALXC_GROUPS

## Mounts and filesystems
# TODO: rootfs (do not set, defaults are ok)
#lxc.rootfs = ${KOHALXC_LXCNAME}/$KOHALXC_ROOTFS
#lxc.rootfs = ${KOHALXC_LXCNAME}/$KOHALXC_ROOTFS

## Backend
#lxc.rootfs.backend = dir
#lxc.rootfs.backend = dir

# TODO : in 'fstab' in this dir what to mount and where
#lxc.mount = ${KOHALXC_LXCNAME}/$KOHALXC_FSTAB
#lxc.mount = ${KOHALXC_SETUP}/fstab
#lxc.mount = ${KOHALXC_SETUP}/fstab

# Add additional mount entrys, if needed..
#lxc.mount.entry = /path/inhost mountpoint/incontainer none bind,create=dir 0 0
#lxc.mount.entry = $KOHALXC_SETUP/kohasetup $KOHALXC_SERVER_KOHASETUP none bind,create=dir 0 0
lxc.mount.entry = $KOHALXC_SETUP $KOHALXC_SERVER_KOHALXC none bind,create=dir 0 0
lxc.mount.entry = $KOHALXC_TOOLDIR $KOHALXC_SERVER_KOHATOOLS none bind,create=dir 0 0

#########################
## Network configuration
#########################
# Network type
#lxc.network.type=veth
lxc.network.type=veth

# Bridge
#lxc.network.link=lxcbr0
lxc.network.link=lxcbr0

# TODO: replace dynamic 'VethXYZABC' name (shown in the host)..?
#lxc.network.veth.pair=V${KOHALXC_NAME}
lxc.network.veth.pair=V${KOHALXC_NAME}

# Network flags
#lxc.network.flags=up
lxc.network.flags=up

# TODO: do we we need to set explicit MAC-address..??
#lxc.network.hwaddr=00:16:3e:xx:xx:xx
lxc.network.hwaddr=00:16:3e:xx:xx:xx

# TODO: do wee need to replace the 'eth0' name in container 
# as shown by "ifconfig -a" or "ip link ??
#lxc.network.name=eth0

# TODO: Network Gateway..?
#lxc.network.ipv4.gateway=10.0.3.1

# TODO: Network Address space
#lxc.network.ipv4=10.0.0.3/24

# TODO: Script to run (on host) to set-up our network/NAT-rules
#lxc.network.script.up   = ${KOHALXC_LXCNAME}/${KOHALXC_IPTABLES}

# TODO: Script to run (on host) to set-down our network/NAT-rules
#lxc.network.script.down = ${KOHALXC_LXCNAME}/${KOHALXC_IPTABLES}

############################
## Other configs: hooks etc
############################
#lxc.hook.pre-start = $KOHALXC_LXCPATH/hook-prestart.sh
#lxc.hook.pre-start = $KOHALXC_LXCNAME/hook-lxc.sh
#lxc.hook.pre-mount = /var/lib/lxc/hook-premount.sh
#lxc.hook.mount     = /var/lib/lxc/hook-mount.sh
#lxc.hook.autodev   = /var/lib/lxc/hook-autodev.sh
#lxc.hook.start     = /var/lib/lxc/hook-start.sh
#lxc.hook.start     = /var/lib/lxc/hook-lxc.sh
#lxc.hook.post-stop = /var/lib/lxc/hook-poststop.sh
#lxc.hook.clone     = /var/lib/lxc/hook-clone.sh
#lxc.hook.destroy   = /var/lib/lxc/hook-destroy.sh

############################################################
EOF
    # Show the generated LXC config
    cat $KOHALXC_SETUP_CONFIGDIR/$KOHALXC_LXCCONFIG | colortab

    ## Configure $HOME/Works for this KohaLXC-container

    # KohaLXC-container setups
    mkdir -p $VERBOSE $HOME/Works/kohalxc

    # - link works to new container
    [[ -L $HOME/Works/kohalxc/$KOHALXC_NAME ]] && rm -f $HOME/Works/kohalxc/$KOHALXC_NAME
    ln -s $VERBOSE $KOHALXC_SETUP $HOME/Works/kohalxc/$KOHALXC_NAME | colortab

    # - link container (setup) log to Works/logs
    mkdir -vp $HOME/Works/logs
    [[ -L $HOME/Works/logs/$KOHALXC_NAME.log ]] && rm -f $HOME/Works/logs/$KOHALXC_NAME.log
    ln -s $VERBOSE $KOHALXC_SETUP_LOGFILE $HOME/Works/logs/$KOHALXC_NAME.log | colortab

    # All done..
    #ecd "Done." && return 0
}


## KOHALXC: Remove container init/setup
function kohalxc_remove {
    # _remove will log to KOHALXC-script file, cause the container will be removed
    ech "KOHALXC_SETUP_LOGFILE:" "$KOHALXC_SETUP_LOGFILE"

    ecd "KOHALXC_NAME:" "$KOHALXC_NAME"
    (sapp="info" && kohalxc_info)

    echo && read -p "== $app [remove] Remove init/setup for '$KOHALXC_NAME' (y/n)? " choice
    case "$choice" in
    	y|Y ) ecd "'yes' ==> Ok, starting to remove '$KOHALXC_NAME' ..";;
    	n|N ) ecd "'no' ==> Doing *nothing* ..exiting, bye!"; return;;
    	* ) ecd "Response invalid.. exiting."; return;;
    esac

    # Backup init/setup to 'kohalxc-backup' ..
    [[ $verbose -ne 0 ]] && ecd "Backing up" "$KOHALXC_NAME .."
    KOHALXC_NAME_BACKUP=${KOHALXC_NAME}-backup-`date +%Y%m%d_%H%M`
    [[ -n "$KOHALXC_SETUPDIR_BACKUP" ]] && mkdir $VERBOSE -p $KOHALXC_SETUPDIR_BACKUP &&
	cp -pr $KOHALXC_SETUP $KOHALXC_SETUPDIR_BACKUP/$KOHALXC_NAME_BACKUP | colortab &&
    	diff -rq $KOHALXC_SETUP $KOHALXC_SETUPDIR_BACKUP/$KOHALXC_NAME_BACKUP
    if [[ $? -ne 0 ]]; then
	echo && ecd "Backup failed..exiting!"; return 1
    fi
    [[ -n "$VERBOSE" ]] && (cd $KOHALXC_SETUPDIR_BACKUP/$KOHALXC_NAME_BACKUP && pwd) &&  
	ls -lr $KOHALXC_SETUPDIR_BACKUP/$KOHALXC_NAME_BACKUP

    # Remove the container setup
    ech "Ready to remove the LXC-setup/configss in:" "$KOHALXC_SETUP"
    rm -Ir $KOHALXC_SETUP

    # Remove link to container setup from user Works-dir
    rm -f $HOME/Works/kohalxc/$KOHALXC_NAME

    # Remove link to container logs from user Works-dir
    rm -f $HOME/Works/logs/$KOHALXC_NAME.log

    # All done..
    #ecd "Done." && return 0
}


## KOHALXC: Create new container
function kohalxc_create {
    log=$KOHALXC_SETUP_LOGFILE
    [[ -f $log ]] || log=$KOHALXC_ROOTDIR/log/$app.log

    echo -e "== \e[36m$app [create]\e[0m KOHALXC_NAME:\e[34m$KOHALXC_NAME\e[0m" | tee -a $log
    [[ $verbose -ne 0 ]] && kohalxc_info

    echo -e "== \e[36m$app [create]\e[0m Targeting KOHALXC_LXCNAME=\e[34m$KOHALXC_LXCNAME\e[0m .." | tee -a $log

    [[ ! -f "$KOHALXC_SETUP/$KOHALXC_CONFIGFILE" ]] && \
	 echo -e "!! \e[91m$app [create]\e[0m No KOHALXC-initialization config found ..exiting." && return 1 

    [[ ! -f "$KOHALXC_SETUP/$KOHALXC_LXCCONFIG" ]] && \
	 echo -e "!! \e[91m$app [create]\e[0m No config found to create a LXC ..exiting." && return 1 

    [[ $verbose -ne 0 ]] && cat $KOHALXC_SETUP/$KOHALXC_CONFIGFILE
    source $KOHALXC_SETUP/$KOHALXC_CONFIGFILE

    [[ $verbose -ne 0 ]] && env | grep "KOHALXC_" | sort
    
    [[ $verbose -ne 0 ]] && \
	echo -e "== \e[36m$app [create]\e[0m Creating from \e[94$KOHALXC_SETUP/$KOHALXC_LXCCONFIG\e[0m .."

    # Create the container
    sudo lxc-create \
	 -t ubuntu -n ${KOHALXC_NAME} \
	 --config ${KOHALXC_SETUP}/${KOHALXC_LXCCONFIG} \
	 --lxcpath ${KOHALXC_LXCPATH} \
	 -l ${KOHALXC_SETUP_LOGLEVEL} -o ${KOHALXC_SETUP_LOGFILE} \
	 -- -d $(echo $KOHALXC_DISTRO | awk '{print $1}') -r ${KOHALXC_RELEASE} \
	 --packages ${KOHALXC_PACKAGES} \
	 --auth-key ${KOHALXC_SSHKEY}

    [[ "$?" -ne 0 ]] &&
	 echo -e "!! \e[91m$app [create]\e[0m Container $KOHALXC_NAME couldn't be created..exiting." && return 1	
    # Show host system dir
    echo -e "== \e[36m$app [create]\e[0m Created \e[34m$KOHALXC_NAME\e[0m to \e[95m$KOHALXC_LXCNAME\e[0m" | tee -a $log
    sudo ls -la $KOHALXC_LXCNAME | colortab | tee -a $log
    sudo cat $KOHALXC_LXCNAME/config | colortab | tee -a $log

    #ecd "Done." && return 0
}


## KOHALXC: Start container
function kohalxc_start {
    ech "Starting $KOHALXC_NAME from:" "$KOHALXC_LXCPATH.."

    # Debug info:
    [[ -n "$DEBUG" ]] && (
	ecd "KOHALXC_ORGANIZATION" "$KOHALXC_ORGANIZATION"
	ecd "KOHALXC_SETUP" "$KOHALXC_SETUP"
	ecd "KOHALXC_SETUP_CONFIGDIR" "$KOHALXC_SETUP_CONFIGDIR"
	ecd "KOHALXC_SETUP_CONFIGFILE" "$KOHALXC_SETUP_CONFIGFILE"
	ecd "KOHALXC_LXCCONFIG" "$KOHALXC_LXCCONFIG"
	ecd "KOHALXC_NAME" "$KOHALXC_NAME"
	ecd "KOHALXC_LXCPATH" "$KOHALXC_LXCPATH"
	ecd "KOHALXC_SETUP_LOGDIR" "$KOHALXC_SETUP_LOGDIR"
	ecd "KOHALXC_SETUP_LOGFILE" "$KOHALXC_SETUP_LOGFILE"
	ecd "KOHALXC_SETUP_LOGLEVEL" "$KOHALXC_SETUP_LOGLEVEL"
    )

    # Show tail of LXC-logging directory/file (create if it does not exist already)
    [[ ! -f "$KOHALXC_SETUP_LOGFILE" ]] &&
	echo && ecd "Initialize logging in:" "$KOHALXC_SETUP_LOGDIR .." &&
	mkdir -p $VERBOSE $KOHALXC_SETUP_LOGDIR | colortab &&
	touch $KOHALXC_SETUP_LOGDIR/$KOHALXC_NAME.log
    ech "Previous contents (tail -10) of" "$KOHALXC_SETUP_LOGFILE"
    tail $KOHALXC_SETUP_LOGFILE | colortab 

    # Use our setup-config:'config.conf', if -f given to override the one used with _create
    #RCFILE_OPT="" && [[ -n "$FORCE" ]] && RCFILE_OPT="-F --rcfile=$KOHALXC_SETUP}/$KOHALXC_LXCCONFIG"
    #RCFILE_OPT="" && [[ -n "$FORCE" ]] && RCFILE_OPT="-F"
    RCFILE_OPT="" && [[ -n "$FORCE" ]] &&
	[[ -f $KOHALXC_SETUP/$KOHALXC_LXCCONFIG ]] &&
	RCFILE_OPT="-F --rcfile=$KOHALXC_SETUP/$KOHALXC_LXCCONFIG"
    [[ -n "$DEBUG" ]] && ecd "[debug]:RCFILE_OPT" "$RCFILE_OPT"
    # no custom error log, based on use log-level use system log in: /var/log/lxc
    # - KOHALXC_SETUP_LOGFILE is now '-L console log' for any use of LXC-commands
    # -l "${KOHALXC_SETUP_LOGLEVEL:-INFO}" -L ${KOHALXC_SETUP_LOGFILE} &&
    sudo test -f $KOHALXC_LXCPATH/$KOHALXC_NAME/config && [[ -n "$KOHALXC_SETUP" ]] &&
	sudo -E -P lxc-start -n ${KOHALXC_NAME} $RCFILE_OPT \
	     -L ${KOHALXC_SETUP_LOGFILE} -l "${KOHALXC_SETUP_LOGLEVEL:-INFO}" &&
	(cd ${KOHALXC_WORKS}/${KOHALXC_ORGANIZATION} &&
		sudo chown -c -R --reference=. ${KOHALXC_SETUP} | colortab) ||
	    (ece "Container could not be started for unknown reason or no config found:" \
		 "$KOHALXC_LXCPATH/$KOHALXC_NAME/config"; exit 1)
    
    #ecd "Done." && return 0
}


## KOHALXC: Stop container
function kohalxc_stop {
    ecd "Stopping '$KOHALXC_NAME' from:" "$KOHALXC_LXCPATH .."

    # No custom log, based on the log-level use system log in: /var/log/lxc
    sudo lxc-stop -n ${KOHALXC_NAME}
    #sudo lxc-stop -n ${KOHALXC_NAME} -l "${KOHALXC_SETUP_LOGLEVEL:-INFO}"
    errcode=$?
    # -l "${KOHALXC_SETUP_LOGLEVEL:-INFO}" -o ${KOHALXC_SETUP_LOGFILE}

    # Exists but not running: .. nothing done.
    [[ "$errcode" -eq 2 ]] && 
	ecd "Container already stopped, ok!"

    # Error: show lxcpath/name dir
    [[ "$errcode" -eq 1 ]] && 
	ece " .. failed to stop '$KOHALXC_NAME'.." &&
	sudo ls -l $KOHALXC_LXCPATH/$KOHALXC_NAME | colortab && return 1

    # Stopped: show lxcpath content
    [[ "$errcode" -eq 0 ]] && 
	# Show host system dir
	echo && ech "Done .. stopped" "$KOHALXC_SETUP" &&
	[[ -n $VERBOSE ]] && sudo ls -l $KOHALXC_LXCPATH/$KOHALXC_NAME | colortab

    #ecd "Done." && return 0
}


## KOHALXC: Destroy container from --lxcpath (i.e. $KOHALXC_LXCPATH/NAME)
function kohalxc_destroy {
    ecd "Destroying '$KOHALXC_NAME' from:" "$KOHALXC_LXCPATH/$KOHALXC_NAME .."

    ## Ensure that no offending SSH-key is left in 'known_hosts'..
    #KOHALXC_IPV4=`sudo lxc-info -iH -n ${KOHALXC_NAME}`
    #[[ -n "$KOHALXC_IPV4" ]] && (
    #	ech "Ensure no offending SSH-key is in 'known_hosts' for" "$KOHALXC_IPV4"
    #	ssh-keygen -R $KOHALXC_IPV4
    #)

    ## Destroy LXC in lxc.lxcpath
    # No custom log, based on the log-level use system log in: /var/log/lxc
    sudo lxc-destroy -n ${KOHALXC_NAME} -l "${KOHALXC_SETUP_LOGLEVEL:-INFO}"
    #sudo lxc-destroy -n ${KOHALXC_NAME} "${FORCE}" -l ${KOHALXC_SETUP_LOGLEVEL}
    # -l ${KOHALXC_SETUP_LOGLEVEL} -o $log

    ## Destroy: failure? 
    [[ "$?" -ne 0 ]] &&
	ece "Failed to destroy '$KOHALXC_NAME' - it does not exist/still running?" &&
	sudo ls -l $KOHALXC_LXCPATH && return 1
    
    ## Destroy: success: show --lxcpath (i.e. $KOHALXC_LXCPATH contents)
    ech "Destroyed '$KOHALXC_NAME' from:" "$KOHALXC_LXCPATH"
    sudo ls -l $KOHALXC_LXCPATH | colortab

    #ecd "Done." && return 0
}


## KOHALXC: Run command with attach in container
function kohalxc_attach {
    command=${*:-""}
    ech "Run '$command' in LXC:" "$KOHALXC_NAME"
    #echo "### Running attached in LXC: $KOHALXC_NAME more args: ${@:2}"

    sudo lxc-attach -n ${KOHALXC_NAME} \
	 -L ${KOHALXC_SETUP_LOGFILE} \
	 -l ${KOHALXC_SETUP_LOGLEVEL} -o ${KOHALXC_SETUP_LOGFILE} -- \
	 $command

    #ecd "Done." && return 0
}


## KOHALXC: Login to container in console
function kohalxc_console {
    ## Get the IPV4_address of the LXC
    KOHALXC_IPV4=`sudo lxc-info -iH -n ${KOHALXC_NAME}`

    ech "Login to:" "$KOHALXC_NAME ($KOHALXC_IPV4)"

    sudo lxc-console -n ${KOHALXC_NAME} \
	 -l ${KOHALXC_SETUP_LOGLEVEL} -o ${KOHALXC_SETUP_LOGFILE}

    #ecd "Done." && return 0
}


## KOHALXC: SSH to container (using it's IPV4-address)
function kohalxc_ssh {
    command=$1

    ## Get the IPV4_address of the LXC
    KOHALXC_IPV4=`sudo lxc-info -iH -n ${KOHALXC_NAME} 2>/dev/null`
    [[ -z "$KOHALXC_IPV4" ]] &&
	ece "No ipv4-address found (LXC is not running or does not exist):" "$KOHALXC_NAME" && return 1

    ## Get the LXC-operuser to use in ssh'ing to LXC
    KOHALXC_OPERUSER=$(sudo grep "^# Parameters passed to " $KOHALXC_LXCPATH/$KOHALXC_NAME/config | grep -oP "\-\-user\s+\K\w+")
    [[ -n "$KOHALXC_OPERUSER" ]] &&
	ech "LXC-based SSH-operuser for '$KOHALXC_NAME ($KOHALXC_IPV4)':" \
	    "$KOHALXC_OPERUSER (config:$KOHALXC_SERVER_SSHUSER)"
    ## Use the LXC-based ssh-operuser (unless none was found and config exists)
    [[ -z "$KOHALXC_OPERUSER" ]] &&  [[ -n "$KOHALXC_SERVER_SSHUSER" ]] &&
	KOHALXC_OPERUSER=$KOHALXC_SERVER_SSHUSER
    ## If still no user found, revert to 'ubuntu'
    [[ -z "$KOHALXC_OPERUSER" ]] && KOHALXC_OPERUSER="ubuntu"

    ## Get the ssh-key for host (name)
    KOHALXC_NAME_SSHKEY=$(ssh-keygen -l -F $KOHALXC_NAME)
    [[ -n "$KOHALXC_NAME_SSHKEY" ]] &&
	ech "SSH-key (name-based) for '$KOHALXC_NAME ($KOHALXC_IPV4)':" \
	    "\n$KOHALXC_NAME_SSHKEY"

    ## Get the ssh-key for host (ipv4)
    KOHALXC_IPV4_SSHKEY=$(ssh-keygen -l -F $KOHALXC_IPV4)
    [[ -n "$KOHALXC_IPV4_SSHKEY" ]] &&
	ech "SSH-key (IP-based) for '($KOHALXC_NAME) $KOHALXC_IPV4':" \
	    "\n$KOHALXC_IPV4_SSHKEY"

    ech "SSH as '$KOHALXC_OPERUSER@$KOHALXC_NAME ($KOHALXC_IPV4)' run:" "$command"

    ## Ensure that no offending SSH-key exists in 'known_hosts'..
    [[ -n "$KOHALXC_IPV4" ]] && (
    	[[ -n "$VERBOSE" ]] && ech "Remove any offending SSH-keys for '$KOHALXC_OPERUSER' from './ssh/known_hosts' of" "$KOHALXC_IPV4"
    	OFFENDING_HOSTKEY_CMD=$(ssh -n $KOHALXC_OPERUSER@$KOHALXC_IPV4 2>&1 | grep "ssh-keygen -f.*-R $KOHALXC_IPV4")
	[[ -n "$OFFENDING_HOSTKEY_CMD" ]] && (
	    [[ -n "$VERBOSE" ]] && ech "OFFENDING_HOSTKEY_CMD:" "$OFFENDING_HOSTKEY_CMD"
    	    for ip in $KOHALXC_IPV4; do ssh-keygen -R $ip; done
	)
    )

    ## Run ssh (command) as KOHALXC_OPERUSER in LXC (using it's IPV4-address)
    ssh -t -q $KOHALXC_OPERUSER@$KOHALXC_IPV4 "$command"
    # TODO: should run ssh using it's fullname (CN.lxcdomain)
    # ssh -t -q $KOHALXC_OPERUSER@$KOHALXC_FULLNAME "$command"

    #ecd "Done." && return 0
}


## KOHALXC: run Perl/MMT-commands in the specified container
function kohalxc_mmtrun {
    # Get the IPV4_address of the LXC
    KOHALXC_IPV4=`sudo lxc-info -iH -n ${KOHALXC_NAME}`

    #
    _host-role && ls -la /home/kohalappi/Uploads/dump_*

    # Do not run if container does not have IPv4-address..
    [[ -z $KOHALXC_IPV4 ]] &&
	ece "Container is not running: '$KOHALXC_NAME'" && return 1

    # Set the command
    command="perl --version"

    [[ -n "$VERBOSE" ]] &&
	ech "Run MMT/Perl-'$command' SSHing to:" "$KOHALXC_NAME ($KOHALXC_IPV4)"

    # Do it.. 
    kohalxc_ssh "$command"

    ecd "done."
}


## Start the Web Panel for LXC
# - if configured and if stopped
function kohalxc_lwp {
    ech "Setting/starting up the Web Panel for LXC:" "$KOHALXC_LWP_SCRIPT"
    [[ -x "$KOHALXC_LWP_SCRIPT" ]] &&
	$KOHALXC_LWP_SCRIPT info | grep "Stopped" &&
	sudo $KOHALXC_LWP_SCRIPT start
}


####################################
# Script: CLI options/args handling
####################################

## Sub/command name:
sapp="main"

## Welcome msg 
ecd "Welcome to KOHALXC ($app)" "'${KOHALXC_GITUSER:-$USER}'!"
ech "KOHALXC_ROOTDIR:" "$KOHALXC_ROOTDIR"
#ech "KOHASETUP_TOOLSDIR:" "$KOHASETUP_TOOLSDIR"
#ech "KOHALXC_SETUPS:" "$KOHALXC_SETUPDIR"
## Check the role we have (host=0/lxc=1)
_host-role && islxc=0 || islxc=1; rc=0

## Start the Web Panel for LXC if we are not a container
[[ "$islxc" -eq 0 ]] && (sapp=" lwp" && kohalxc_lwp)

# Reset in case getopts has been used previously in the shell.
OPTIND=1         

# Initialize some script opt/arg defaults
verbose=0 && VERBOSE=""
force=0 && FORCE=""
debug=0 && DEBUG=""

while getopts "h?fvdi:n:" opt; do
    case "$opt" in
	h|\?)
	    _usage
	    exit 0
	    ;;
	d)  debug=1; DEBUG="-d"; # Do not skip ansible :debug tags
	    KOHALXC_ANSIBLE_SKIPTAGS=
	    ;;
	f)  force=1; FORCE="-f";
	    ;;
	i)  KOHALXC_ANSIBLE_INVENTORY=$OPTARG;
	    [[ -n "$VERBOSE" ]] &&
		ech "Ansible inventory set to:" "$KOHALXC_ANSIBLE_INVENTORY"
	    KOHALXC_ANSIBLE_CMDOPTS+=" $KOHALXC_ANSIBLE_SKIPTAGS"
	    ;;
	v)  verbose=1; VERBOSE="-v";
	    ;;
	n)  KOHALXC_NAME=${OPTARG%%.*}
	    [[ $OPTARG =~ "." ]] && (
		 KOHALXC_DOMAINNAME=${OPTARG#*.}
		 KOHALXC_FULLNAME=${KOHALXC_NAME}.${KOHALXC_DOMAINNAME}
		 [[ -n "$VERBOSE" ]] &&
		     ech "LXC-container full name set to:" "$KOHALXC_FULLNAME"
	     )
	    [[ -n "$VERBOSE" ]] &&
		ech "LXC-container name set to:" "$KOHALXC_NAME"
	    # Set the path to container setup directory
	    KOHALXC_SETUP=${KOHALXC_SETUPDIR}/$KOHALXC_NAME
	    # Set the path to container-specific configs directory
	    KOHALXC_SETUP_CONFIGDIR=${KOHALXC_SETUP}/$KOHALXC_CONFIGDIR
	    # Set the full path to container KOHALXC-config file: 'kohalxc.conf'
	    KOHALXC_SETUP_CONFIGFILE=${KOHALXC_SETUP_CONFIGDIR}/$KOHALXC_CONFIGFILE
	    # Set the full path to container LXC-config file: 'config.conf'
	    KOHALXC_SETUP_LXCCONFIG=${KOHALXC_SETUP_CONFIGDIR}/$KOHALXC_LXCCONFIG
	    # Set the path to KOHALXC/container-specific logdir
	    KOHALXC_SETUP_LOGDIR=${KOHALXC_SETUP}/logs
	    # Set the full path to KOHALXC/container-specific logfile: 'KOHALXC_NAME.log'
	    KOHALXC_SETUP_LOGFILE=${KOHALXC_SETUP_LOGDIR}/${KOHALXC_NAME}.log
	    ;;
    esac
done

shift $((OPTIND - 1))

## Show info about the env and container (if given)
[[ -z "$@" && -n "$VERBOSE" ]] && echo &&
    VERBOSE="-v" && (sapp="info" && kohalxc_info) &&
    exit 0

## If no args are present show the usage only
[[ -z "$@" ]] && echo &&
    _usage &&
    exit 0

# If no container was given
# or setupdir does not exist
# and 'ansible' or 'init' or 'remove' or 'ssh' or 'destroy' or 'stop'
#      or 'start' was not given as command
# - show info, usage and exit..
if [[ ( -z "$KOHALXC_NAME" ||
	      ! -d "$KOHALXC_SETUPDIR/$KOHALXC_NAME" ) &&
	  ( ! "$@" =~ "ansible" && ! "$@" =~ "init" && ! "$@" =~ "remove" && ! "$@" =~ "ssh" && ! "$@" =~ "destroy" && ! "$@" =~ "stop" && ! "$@" =~ "start" ) ]]; then
    echo && (sapp="info" && kohalxc_info)
    ece "Warn:" "Script needs [-n container-name] ..exiting."
    _usage
    echo && exit 1
fi

# Source the setup init environment (if the the container has one)
[[ -n "$VERBOSE" ]] &&
    ( ecd "KOHALXC_SETUP" "$KOHALXC_SETUP"
      ecd "KOHALXC_CONFIGFILE" "$KOHALXC_CONFIGFILE"
      ecd "KOHALXC_SETUP_CONFIGDIR" "$KOHALXC_SETUP_CONFIGDIR"
    )
[[ -f "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE" ]] && \
    source "$KOHALXC_SETUP_CONFIGDIR/$KOHALXC_CONFIGFILE"
[[ -n "$VERBOSE" ]] && \
    echo && ecd "Environment for KOHALXC:" && \
    env | grep "KOHALXC_" | colortab | sort && echo

for i in "$@"; do
    case "$i" in
	ansible)
	    shift
	    sapp="ansible" && kohalxc_ansible "$@";
	    break;
	    ;;
	init)
	    shift
	    sapp="init" && kohalxc_init;
	    ;;
	create)
	    [[ ! -d "$KOHALXC_SETUP" ]] &&
		ece "No container config to create LXC.. exit." &&
		exit
	    shift
	    sapp="create" && kohalxc_create;
	    ;;
	start)
	    [[ -n "$FORCE" ]] && [[ ! -d "$KOHALXC_SETUP" ]] &&
		ece "No container config found to start LXC with -F .. exit." &&
		exit;
	    shift
	    sapp="start" && kohalxc_start;
	    ;;
	attach)
	    [[ ! -d "$KOHALXC_SETUP" ]] &&
		ece "No container config found to attach to.. exit." &&
		exit;
	    shift;
	    sapp="attach" && kohalxc_attach "$@";
	    ;;
	console)
	    [[ ! -d "$KOHALXC_SETUP" ]] &&
		ece "No container config found to login to.. exit." &&
		exit;
	    shift;
	    sapp="console" && kohalxc_console;
	    ;;
	ssh)
	    #[[ ! -d "$KOHALXC_SETUP" ]] &&
	    #	ece "No container config found to ssh to.. exit." && exit;
	    shift;
	    sapp="ssh" && kohalxc_ssh "$@";
	    break;
	    ;;
	stop)
	    #[[ ! -d "$KOHALXC_SETUP" ]] &&
	    #	ece "No container config found to stop.. exit." && exit;
	    shift;
	    sapp="stop" && kohalxc_stop;
	    ;;
	destroy)
	    sudo test ! -d $KOHALXC_LXCPATH/$KOHALXC_NAME &&
		ece "Container not in $KOHALXC_LXCPATH to destroy.. exit." &&
		exit;
	    shift
	    sapp="destroy" && kohalxc_destroy;
	    ;;
	remove)
	    [[ ! -d "$KOHALXC_SETUP" ]] &&
		ece "No container config found to remove.. exit." &&
		exit;
	    shift
	    sapp="remove" && kohalxc_remove;
	    ;;
	mmtrun)
	    shift;
	    sapp="perl" && kohalxc_mmtrun "$@";
	    break;
	    ;;
	*)
	    _usage
	    exit 2
	    ;;
    esac
done

#ecd "Done." && echo
exit 0
