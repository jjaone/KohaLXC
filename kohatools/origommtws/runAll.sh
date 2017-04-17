#!/bin/bash
#perl migrate.pl -p &> logs/1.preprocess.log
perl migrate.pl -b &> logs/2.biblios.log
perl migrate.pl -i &> logs/3.items.log
perl migrate.pl -B &> logs/4.borrowers.log
perl migrate.pl -c &> logs/5.checkouts.log
perl migrate.pl -f &> logs/6.fines.log
perl migrate.pl -H &> logs/7.holds.log
perl migrate.pl -r &> logs/8.rotatingCollections.log
perl migrate.pl -a &> logs/9.acquisitions.log

bash sftpSend.sh
