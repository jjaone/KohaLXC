#!/bin/sh
# File: kohatools/ppmmtws/ConversionTools/liqlocdeConstructor.sh
# #############################################################################
# Code is part of the KohaLXC/kohatools Ansible/Bash setup tooling scripts
# for Koha/ILS-development, deployment & database conversion/migration tasks.
# Author: Pasi Korkalo, Koha-Suomi Oy, Oulu/Finland.
# Author: Jukka Aaltonen, Koha-Lappi, Rovaniemi City Library, Lapland/Finland.
# License: Gnu General Public License version 2 (or later).
#
# Description:
# KohaLXC/kohatools/ppmmtws conversion scripts for Ansible/Bash tooling:
# (requires in Ubuntu Server LTS (14.04/16.04) guest/host environments)
# - Conversion Table Constructor Version 160816 - Written by Pasi Korkalo
# - Sheetparser/builder for translation tables from excel/CSV to perl for PP/MMT
# - used by the ./makeliqlocde.sh (and from Ansible/KohaLXC-playbooks)
# 
# Created:  2016-08 by "Pasi Korkalo"
# Modified: 2017-01 by "Jukka Aaltonen" (@jjaone) 
# #############################################################################

getfield() {
  echo $2 | cut -f $1 -d ';'
}

qw() {
  IFS=' '; first=0
  for item in $@; do
    test $first -eq 0 && first=1 || output="$output, "
    output="$output'$item'"
  done
  unset IFS
  echo $output
}

# Preprocess tables and create a tempfile
# If we got some lines without the correct amount of fields, just drop them, they're probably notes anyway
# The first field should contain a library id-number, drop everything that isn't a number
tempfile="$(date +%s).tmp"
cat $1 | cut -f 1-4,6,7-8,10-11 -d ';' | sed 's/ *;/;/g;s/; */;/g' | grep '^[0-9]*;' > $tempfile

# test -n "$2" && libid=$(($2 - 1)) # This is for combining output from several files, prevents library id's from overlapping

# Initialize this to make comma (,) behave correctly in the output
firstdone=0

# Library level handling
for libid in $(cat $tempfile | cut -f 1 -d ';' | sort -n | uniq); do

  # Communal codes for libraries
  for kir in $(grep "^$libid" $tempfile | cut -f 2 -d ';' | sort -n | uniq); do

    # libid=$(($libid + 1)) # Running libid (should this come from somewere instead???)
 
    # , in the front is correct for every entry but the very first one
    test $firstdone -eq 0 && firstdone=1 || echo ","
  
    echo -n "$libid => {" #\n\t0 => {\n\t\t0 => [ '$kir', '', '' ],\n\t}"
    
    # Branch level handling
    firstbranch=0
    for tp in $(grep ";$kir;" $tempfile | cut -f 3 -d ';' | sort -n | uniq); do

      test $firstbranch -eq 0 && firstbranch=1 || echo -n ","
      echo "\n\t$tp => {" 

      # Department level handling
      for line in $(cat $tempfile | grep "^$libid;$kir;$tp;"); do

        locid=$(getfield 4 $line | sed 's/^0*//g') # Locid, strip leading zeros

        test -z $locid && locid="0" 

        pallasdepartment="$(getfield 5 $line)" # Pallas department
        kohadepartment="$(getfield 6 $line)" # Koha department
        shelvingloc="$(getfield 7 $line)" # Shelving location

        test $locid -gt 0 && test -z "$pallasdepartment" && test -z "$kohadepartment" && test -z "$shelvingloc" && continue # If they're all empty, skip this line (is this the correct way to deal with them?)
        test -n "$shelvingloc" || shelvingloc="KONVERSIO" # Shelving location handling for lines missing that piece of information

         # Extra fields to be inserted at the end of table rows
        addinfo="$(getfield 8 $line)"
        noloan="$(getfield 9 $line)"

        # Broken intentionally for now
        test -n "$addinfo" && addinfo=", '$addinfo'" || addinfo=", ''"

        test -n "$noloan" && noloan=", '$noloan'" || unset noloan

        # Spit out the processed line
        echo "\t\t$locid => [ '$pallasdepartment', '$kohadepartment', '$shelvingloc'$addinfo$noloan ],"

      done

      echo -n "\t}"

    done

    echo -n "\n}"

  done

done

echo ","
rm $tempfile

# echo "$libid" > libid.tmp # Store the last libid for serial processing of multiple files
