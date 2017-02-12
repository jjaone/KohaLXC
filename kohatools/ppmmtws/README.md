## PP/MMT - Migration Tool in Perl for PallasPro FinMarc/Marc21 conversions

**Perl and shell scripts to convert PallasPro/Ingress database FinMarc dumps**<br/>
**to Marc 21 XML format that can be migrated to Koha in libraries in Finland.**<br/>

__This code is part of KohaLXC/kohatools Ansible/Bash tooling environment  
for Koha/ILS-development, deployment & database conversion/migration.__ 

**Author**: Olli-Antti Kivilahti, systems developer, Koha-Suomi Oy, Joensuu/Finland
**Author**: Jukka Aaltonen, Linux/opensource developer, Koha-Lappi, Finland.
**Organization**: Rovaniemi City Library, Lapland (2016/06 - 2017/05)
**License**: GNU General Public License (GPL) version 3

### Usage: directly from the command line shell in target host
```
$ cd $KOHALXC_TOOLDIR/ppmmtws/PerlMMT
$ perl import.pl config.xml
```

### Usage:
#### Running conversion in LXC as KohaLXC/Ansible play from control host:
#### * -i = inventory in which to setup and run the conversion Ansible play
#### * -t = comma separetd list of roles:task's that are to be run
#### Explicitly ensures target server, dump data and LXC enviroment are setup:
#### * conversion step is run iff `hostnode_ppmmtenv_enabled` has been set
#### * play creates dedicated LXC-container in which the conversion is run
#### * setting `kohalxcs_ppmmtenv_runconv_polling=0' runs conversion in async mode

```
$ cd $KOHALXC_ROOTDIR/kohaplay/kohalappi
$ kohalxc -i inventory/development ansible -t hostnode:srvenv-setup,hostnode:dataenv-setup,hostnode:lxcenv-setup,hostnode:postrole,kohalxcs:setup -e "kohalxcs_ppmmtenv_runconv_polling=0"
```
