## Origo/MMT - Master Migration Tool fo Origo/Koha conversions

**Perl and shell scripts to convert Origo/???? database FinMarctext dumps**<br/>
**to Marc 21 XML format that can be migrated to Koha in libraries in Finland.**<br/>

_This code is part of KohaLXC/kohatools Ansible/Bash tooling environment  
for Koha/ILS-development, deployment & database conversion/migration._ 

**Author**: Olli-Antti Kivilahti, systems developer, Koha-Suomi Oy, Finland.<br/>
**Author**: Jukka Aaltonen, Linux/opensource developer, Koha-Lappi, Finland.<br/>

**Organization**: Rovaniemi City Library, Lapland (2016/06 - 2017/05)<br/>
**License**: GNU General Public License (GPL) version 3

### Installing/run: original instructions for Koha/Origo conversions/migrations:

#### Origo migration tools using Perl scripts

=======================
INSTALL INSTRUCTIONS :)
=======================

If you are using the default configuration, create required directories:
```
mkdir OrigoSource
mkdir OrigoValid
mkdir OrigoComplete
mkdir logs
```
Copy the DB dump from "Axiell Jätte Bra" to the root of OrigoSource.

================
RUN INSTRUCTIONS
================

``` 
bash -x runAll.sh
```

For more information don't hesitate to read the code!

### [TODO]: Usage (KohaLXC/host): directly from the command line shell:
```
$ cd $KOHALXC_TOOLDIR/origommtws
$ ./runAll.sh
```

### [TODO]: Usage (KohaLXC/container): as Ansible play from control host:
```
$ cd $KOHALXC_ROOTDIR/kohaplay/kohalappi
$ kohalxc -i inventory/development ansible\
 -t hostnode:srvenv-setup,hostnode:dataenv-setup,hostnode:lxcenv-setup,\
  hostnode:postrole,kohalxcs:setup -e "kohalxcs_origommtenv_importchains=all"
```

#### Explicitly ensures target server, dump data and LXC enviroment are setup:
* conversion step is run iff `hostnode_origommtenv_enabled` has been set(up)
* dedicated LXC-container created to mount setup/dumps and to run conversion
* by default asynchronous run for 'all' configured importchains, use
* `-e "hostnode_origommtenv_importchains=Patrons"` to configure importchains
* `-e "kohalxcs_origommtenv_polling=30"` to make conversion poll interval 30 s

#### Options used:
* -i = inventory in which to setup and run the conversion play
* -t = comma separetd list of role:task(s) that are to be run
* -e = additional play vars/settings to change the behaviour
