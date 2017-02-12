## PP/MMT - Master Migration Tool for PallasPro/Koha conversions

**Perl and shell scripts to convert PallasPro/Ingress database FinMarc dumps**<br/>
**to Marc 21 XML format that can be migrated to Koha in libraries in Finland.**<br/>

_This code is part of KohaLXC/kohatools Ansible/Bash tooling environment  
for Koha/ILS-development, deployment & database conversion/migration._ 

**Author**: Olli-Antti Kivilahti, systems developer, Koha-Suomi Oy, Finland.<br/>
**Author**: Jukka Aaltonen, Linux/opensource developer, Koha-Lappi, Finland.<br/>

**Organization**: Rovaniemi City Library, Lapland (2016/06 - 2017/05)<br/>
**License**: GNU General Public License (GPL) version 3

### Usage: directly from the command line shell in target host
```
$ cd $KOHALXC_TOOLDIR/ppmmtws/PerlMMT
$ perl import.pl ../config.xml
```

### Usage: in hostnode/LXC as Ansible play from control host:
#### Explicitly ensures target server, dump data and LXC enviroment are setup:
* conversion step is run iff `hostnode_ppmmtenv_enabled` has been set(up)
* dedicated LXC-container created to mount setup/dumps and to run conversion
* setting `kohalxcs_ppmmtenv_runconv_polling=0` makes conversion run asynchronous
#### Options
* -i = inventory in which to setup and run the conversion Ansible play
* -t = comma separetd list of roles:task's that are to be run
* -e = additional play vars that to change the behaviour
```
$ cd $KOHALXC_ROOTDIR/kohaplay/kohalappi
$ kohalxc -i inventory/development ansible\
 -t hostnode:srvenv-setup,hostnode:dataenv-setup,hostnode:lxcenv-setup,\
  hostnode:postrole,kohalxcs:setup\
 -e "kohalxcs_ppmmtenv_runconv_polling=0"
```
