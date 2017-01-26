## KohaLXC
 
**Linux shell tooling and Ansible playbook for Koha/ILS-related server and** <br/> 
**LXC development, deployment and migration tasks/setups for Koha-Lappi.** <br/>  

This code is part of KohaLXC/kohatools Ansible/Bash tooling environment  
for Koha/ILS-development, deployment & database conversion/migration tasks.  

**Author**: Jukka Aaltonen, Linux/opensource developer, Koha-Lappi, Finland.  
**Organization**: Rovaniemi City Library, Lapland (Koha-Lappi project).
 
**License**: GNU General Public License version 3.

### Install
```
$ lsb_release -d && whoami
Description: Ubuntu (Linux) 16.04 LTS
kohadev

$ export KOHALXC_WORKS=~/Works
$ cd && mkdir -p $KOHALXC_WORKS
$ export KOHALXC_ORGANIZATION=KohaLappi
$ export KOHALXC_ROOTDIR=$KOHALXC_WORKS/KohaLXC
$ git clone https://github.com/jjaone/KohaLXC.git $KOHALXC_WORKS
```

### Usage
```
$ kohalxc

== ================================================================== ==
== @kohacmh: 2016-12-20_16:12:20:
== /home/kohadev/bin/kohalxc ''
== logging to logfile: /home/kohadev/Works/KohaLXC/log/kohalxc.log
== ================================================================== ==
== kohalxc [main]: Welcome to KOHALXC (kohalxc) 'kohadev'!
== kohalxc [main]: KOHALXC_ROOTDIR: /home/kohadev/Works/KohaLXC
== kohalxc [main]: Hostname (LXC-guest/host): kohacmh (Host/platform)
== kohalxc [ lwp]: Setting/starting up the Web Panel for LXC: /home/kohadev/bin/lwp

== kohalxc [main]: Usage: "kohalxc -f -v [-n CN ] [ansible|init|create|remove|start|attach|console|ssh|stop|destroy]"

== kohalxc: Done.
```

### Ansible plays using 'kohalxc'
All roles/tasks in 'localdev'
```
$ kohalxc -i inventory/localdev ansible
```
List tags in 'development' (be verbose)
```
$ kohalxc -v -i inventory/development ansible --list-tags
```
Setup server and conversion/MMT environments in 'development'
```
$ kohalxc -i inventory/development ansible -t hostnode:setup
```
Status tasks for hostnodes in 'testing' (be debug verbose)
```
$ kohalxc -d -v -i inventory/testing ansible -t hostnode:status
```
Server host environment setup tasks in 'testing' w/ env variable (increase verbosity)
```
$ kohalxc -i inventory/testing ansible - t hostnode:srvenv-setup -e "hostnode_reboot_enabled=false" -v
```
Build, deploy and (re)start Koha-related LXC-container(s) to run e.g. PP/MMT-conversions 
```
$ kohalxc -i inventory/testing ansible -t hostnode:lxcenv-setup,hostnode:postrole,kohalxcs:setup
```

### Ansible plays using system 'ansible-playbook'
* _must be run in the $KOHALXC_ANSIBLE_PLAYBOOKS directory_
* _pass needed options and secrets on invocation_

Play all tasks of 'common' and 'hostnode' roles directly in 'development' 
```
$ cd $KOHALXC_ROOTDIR/kohaplay/kohalappi
$ ansible-playbook play-hostnodes.yaml -i inventory/development --vault-password-file .my.vault.pass
```
