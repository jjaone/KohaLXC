
################################################
## KohaLXC/kohatools: devenv profile settings ##
################################################

#####################################################################
## KohaLXC development/setup client/server environment (defaults) ##
#####################################################################
# Koha-works main directory
export KOHALXC_WORKS="/KohaData/Works"
# KohaSuomi organization
export KOHALXC_ORGANIZATION="KohaLappi"
# Koha-datas/LXC-setups main directory
export KOHALXC_SETUPDIR="${KOHALXC_WORKS}/${KOHALXC_ORGANIZATION}/kohalxc"
export KOHALXC_DATADIR="${KOHALXC_WORKS}/${KOHALXC_ORGANIZATION}/kohadata"
# LXC environment: clients & server setups and configs
# Client tools root
export KOHALXC_ROOTDIR="$KOHALXC_WORKS/KohaLXC"
# Client kohatools (to be mounted to LXC)
export KOHALXC_TOOLDIR="$KOHALXC_WORKS/KohaLXC/kohatools"

# Make sure no LXC-name or MMT-dataset nor LXC-setup dir are specfied
export -n KOHALXC_NAME
export -n KOHALXC_DATASET
export -n KOHALXC_SETUP

# Developer: author and git-user
export KOHALXC_GITUSER=`whoami`
export KOHALXC_GITEMAIL=
export KOHALXC_AUTHOR="Koha Developer"


############################
## Shell/bash environment ##
############################
# Shell history settins
#export HISTCONTROL=ignoreboth
export HISTFILESIZE=-1
export HISTSIZE=-1
export HISTTIMEFORMAT='%F_%T '

# LESS
export LESS=-XR

# locale
export LC_COLLATE=C

# shell aliases
alias l='ls -laF'
# prompt
# PS1=

# source ~/.kohalxc.rc if available
#[[ -f ~/-kohalxc.rc ]] && source ~/.kohalxc.rc
