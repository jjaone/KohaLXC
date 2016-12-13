#!/bin/bash

# #############################################################################
# Code is part of the KohaLXC/kohatools Ansible/Bash setup tooling scripts
# for Koha/ILS-development, deployment & database conversion/migration tasks.
# Author: Jukka Aaltonen, Koha-aLappi, Rovaniemi City Library, Lapland/Finland.
# License: Gnu General Public License version.
#
# Description:
# KohaLXC/kohatools setup (kohasetup.sh) shell scripts for Koha/LXCs:
# - should work in Ubuntu Server LTS (14.04/16.04) guest/host environments
# - configure/setup "srvenv", "devenv", "mdbenv" and "kohaenv" in/for KohaLXCs
#
# Created: 2016-07 by "roikohadev" (@jjaone)
# Modified:
# #############################################################################

## Script/application name
app="kohasetup"

## Are we an LXC-container or host?
islxc=0 # 0 = host, 1 = lxc

## Kohatools/'kohasetup' shared configurations, tools and common functions:
# - for LXC  in dir: "$HOME/kohatools/conf.d"
# - for host in dir: "$KOHALXC_ROOTDIR/kohatools/conf.d"
KOHASETUP_CONFIGDIR="${KOHALXC_ROOTDIR:-$HOME}/kohatools/conf.d"

# Source our main configuration
KOHASETUP_CONFIGFILE="${KOHASETUP_CONFIGDIR}/$app.conf"
. $KOHASETUP_CONFIGFILE

## Usage: kohasetup: this script usage
function _usage {
    ecd "Usage:" "\"$app [-h] [-v] [-c]  <command: srv | dev | mdb | koha>\""
}

## Move to home and keep the 'sudofication' of the script valid..
cd $HOME
sudo ls 2>&1 >/dev/null
[[ $? -ne 0 ]] && \
    err="Sudo failed..exit" && exit 1;

## Exec to redirect all of stdout/stderr to file (and to screen)..
exec &> >(tee -a $log)
echo
echo "== ================================================================== =="
echo "== @$host: $date: $0 '$@'"
echo "== logging to: $log"
echo "== ================================================================== =="


#####################################################################
## srvenv: show status, setup and configure server env
# - status, install, setup
# - localization: locale, timezone, ntp setup
# $1 = sub-command: i.e '$sapp': "status" (default) or "config"
#####################################################################
#
function srvenv {
    #rc=
    echo && ecd "=========================================== =="
    case "${sapp:=$1}" in
	status) 
	    # ecd "Status of server env and configs.."
	    srvenv-status || rc=$?
	    ;;
	config)
	    # && ecd "Setup server env and configs.."
	    (_pckgs-install $KOHASETUP_SRVENV_PCKGS &&
		    srvenv-setup_localize) || rc=$?
	    ;;
	*) [[ -n "$VERBOSE" ]] && srvenv-status ||
		   ece "Warn: unknown sub-command, nothing done!";;
    esac

    return $rc
}


#####################################################################
## devenv: show status, setup and configure dev env
# - status, install/setup
# - profile env: username, LC_COLLATE, LESS, HIST*, .. 
# - localization: locale, timezone, ntp setup
# - git
# $1 = sub-command: i.e '$sapp': "status" (default) or "config"
# $2 = mdbsrv: either "mysql/-stable" (default) or "mariadb/-stable"
#     - if emtpy defaults to KOHASETUP_MDBENV_SRVNAME
#####################################################################
#
function devenv {
    rc=
    ## The database server we are using
    mdbsrv=${2:-$KOHASETUP_MDBENV_SRVNAME}
    [[ -n "$DEBUG" ]] && ecd "mdbsrv:$mdbsrv"

    echo && ecd "================================================ =="
    case "${sapp:=$1}" in
	status) 
	    # ecd "Status of developer settings and configurations.."
	    devenv-status || rc=$?
	    ;;
	config)
	    # ecd "Setup developer settings and configuration.."
	    (_pckgs-install $KOHASETUP_DEVENV_PCKGS &&
		  devenv-setup) || rc=$?
	    ;;
	*) [[ -n "$VERBOSE" ]] && devenv-status ||
		   ece "Warn: unknown sub-command., nothing done.";;
    esac
    
    return $rc
}


#####################################################################
## mdbenv: show status, setup and configure database environment
# - status, install/setup
# - client config to connect to our database
# - install db-server packages
# - setup access for root
# - enable remote connectivity
# - start the service
# - show that the db is available
# $1 = sub-command: i.e '$sapp': "status" (default) or "config"
# $2 = mdbsrv: either "mysql" (default) or "mariadb"
#     - if emtpy defaults to KOHASETUP_MDBENV_SRVNAME
#####################################################################
#
function mdbenv {
    rc=0
    mdbsrv=${2:-$KOHASETUP_MDBENV_SRVNAME}
    echo && ecd "================================================ =="
    case "${sapp:=$1}" in
	status) 
	    # ecd "Status of database settings and configurations.."
	    mdbenv-status "$mdbsrv" || rc=$?
	    ;;
	config)
	    [[ -n "$DEBUG" ]] && ecd "KOHASETUP_MDBENV_PCKGS[$mdbsrv]" \
				     "${KOHASETUP_MDBENV_PCKGS[$mdbsrv]}"
	    mdbsrv_pckg=`echo ${KOHASETUP_MDBENV_PCKGS[$mdbsrv]} | awk '{print $1;}'`
	    ech "Prepare to install/setup database:" \
		"debconf-set-selections for '$mdbsrv_pckg'"
	    if [[ -n "$mdbsrv_pckg" ]]; then
		# prepare debconf for mysql/mariadb noninteractive install w/ empty root pass
		sudo debconf-set-selections <<< "$mdbsrv_pckg mysql-server/root_password password"
		sudo debconf-set-selections <<< "$mdbsrv_pckg mysql-server/root_password_again password"
	    fi
	    (_pckgs-install "${KOHASETUP_MDBENV_PCKGS[$mdbsrv]}" &&
		    mdbenv-setup "$mdbsrv") || rc=$?
	    ;;
	*) [[ -n "$VERBOSE" ]] && mdbenv-status "$mdbsrv" ||
		   ece "Warn: unknown sub-command, nothing done for '$mdbsrv'.";;
    esac
    
    return $rc
}


#####################################################################
## kohaenv: show status and setup/config koha-server/app environment
# (operations: status, check, verify, install/setup, config, etv)
# - check that we are actually a LXC-container
#
# - client config to connect to our database
# - install db-server packages
# - setup access for root
# - enable remote connectivity
# - start the service
# - show that the db is available
# $1 = sub-command: i.e '$sapp': "status" (default) or "config"
# $2 = mdbsrv: (default: "mysql") or "mariadb"
#     - if emtpy defaults to KOHASETUP_MDBENV_SRVNAME
# $3 = dbhost: (default: "localhost") or "10.0.3.nnn"
#     - if emtpy defaults to KOHASETUP_MDBENV_DBHOST
#####################################################################
#
function kohaenv {
    rc=0
    mdbsrv="${2:-$KOHASETUP_MDBENV_SRVNAME}"
    mdbhost="${3:-$KOHASETUP_MDBENV_DBHOST}"
    echo && ecd "================================================ =="
    case "${sapp:=$1}" in
	status) 
	    # ecd "Status of koha-related settings and configs.."
	    # - return value: 0 = host, 1 = lxc
	    kohaenv-status "$mdbsrv" "$mdbhost"; islxc=$?; rc=0;
	    ;;
	config)
	    # ecd "Setup koha-server/application settings and configs."
	    (_pckgs-install "$KOHASETUP_KOHAENV_PCKGS" &&
		    kohaenv-setup "$mdbsrv" "$dbhost") || rc=$?
	    ;;
	*) [[ -n "$VERBOSE" ]] && kohaenv-status "$mdbsrv" "$dbhost" ||
		   ece "Warn: unknown sub-command, nothing done for Koha.";;
    esac
    
    return $rc
}


####################################
# Script: CLI options/args handling
####################################

## Welcome msg 
ecd "Welcome to KOHALXC ($app)" "'${KOHALXC_GITUSER:-$USER}'!"
ech "KOHASETUP_TOOLSDIR:" "$KOHASETUP_TOOLSDIR"
ech "KOHASETUP_LOGDIR:" "$KOHASETUP_LOGDIR"
ech "KOHASETUP_CONFIGDIR:" "$KOHASETUP_CONFIGDIR"

## Check the role we have (host=0/lxc=1)
_host-role && islxc=0 || islxc=1; rc=0

## [TODO]: What is this, sets the var in LXC, for what?
KOHASETUP_KOHALXC="$HOME/kohalxc/config"
[[ $(_host-role) && -d "$KOHASETUP_KOHALXC" ]] &&
    ech "KOHASETUP_KOHALXC:" "$KOHASETUP_KOHALXC"

## Initialize some script opt/arg defaults
verbose=0 && VERBOSE=""
force=0 && FORCE=""
sapp="status"

## Script options
# Reset in case getopts has been used previously in the shell.
OPTIND=1
# use getopt for script-options
while getopts "h?dm:vc" opt; do
    case "$opt" in
	h|\?) _usage; exit 0 ;;
	d)  debug=1; DEBUG="-d" ;;
#	f)  force=1; FORCE="-f" ;;
	m)  mopt=$OPTARG ;;
	v)  verbose=1; VERBOSE="-v" ;;
	c)  sapp="config" ;;
    esac
done
shift $((OPTIND - 1))

## Handle commandline args
[[ -z "$@" ]] && _usage

for cmd in "$@"; do
    rc=
    [[ ! -f "$KOHASETUP_CONFIGDIR/env.${cmd}/${cmd}env.conf" ]] ||
	[[ "srv" != "$cmd" && "dev" != "$cmd" && "mdb" != "$cmd" && "koha" != "$cmd" ]] &&
	    ece "Unknown cmd '$cmd', no env: '$KOHASETUP_CONFIGDIR/env.${cmd}/${cmd}env.conf'" &&
	    _usage && exit 0
    
    #app="setup-${cmd}"
    app="${cmd}env"
    . $KOHASETUP_CONFIGDIR/env.${cmd}/${app}.conf >/dev/null 2>&1 ||
	(sapp="Warn" &&
		ech "Did not find correct setup env:" "$KOHASETUP_CONFIGDIR/env.${cmd}")
    ${cmd}env "$sapp" "$mopt"

    ## Error: something went wrong
    [[ $rc -ne 0 ]] &&
	echo && ece "Error: something went wrong in '${cmd}env:($rc)'";

    ## Success: <command>-environment related tasks done
    [[ $rc -eq 0 ]] &&
	echo && ecd "Status:" "All '${cmd}'-environment setups done/shown. [ok]";

    app="kohasetup"
done

## Normal exit, echo and clean-up/errors handled by our trap
exit 0
