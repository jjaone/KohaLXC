#!/bin/bash
logfile=$1;
grep -Pi '008_23_for_vi:\d+' $logfile | perl -e 'use Data::Dumper; %t; while(<>){ @g=split(/\s+/,$_); grep{@f=split(/:/,$_); $t{$f[0]} += $f[1]} @g }print $t; foreach $key (keys %t){print "$key : $t{$key}\n";}'
