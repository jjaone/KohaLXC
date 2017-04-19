#!/bin/sh
othernames=0; lastothernames=0
IFS='
'
for each in $(cat 01_patrons* ); do
  while test $lastothernames -eq $othernames; do
    othernames="$(date +%s%N | cut -c 1-12)"
  done
  otherdashed="$(echo $othernames | cut -c 1-4)-$(echo $othernames | cut -c 5-8)-$(echo $othernames | cut -c 9-12)"
  echo $each | sed "s/}, 'Item' );/, 'othernames' => '$otherdashed'}, 'Item' );/g"
  lastothernames=$othernames
done
unset IFS
