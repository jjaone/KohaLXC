#!/bin/bash
# File: kohatools/ppmmtws/ConversionTools/makeliqlocde.sh
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
# - generate '$org_Units' mapping for PP/MMT: 'licloqde_translation.pm-map'
# - works as CLI-script or as 'kohalxc'-tool or from Ansible/KohaLXC-playbooks
# 
# Created:  2015-04 by "Pasi Korkalo, Oulu"
# Modified: 2016-12 by "Jukka Aaltonen" (@jjaone) 
## #############################################################################

## Base name of TranslationTable to be generated, e.g. 'liqlocde_translation'
SRC_NAME="$1"
[[ -z "$SRC_NAME" ]] && echo "== Error: no TranslationTable defined.. exiting." && echo && exit 2
echo && echo "== Name of the TranslationTable to be generated SRC_NAME=$SRC_NAME"

KOHALXC_TOOLDIR="${KOHALXC_TOOLDIR:=$KOHALXC_WORKS/KohaLXC/kohatools}"
echo && echo "== KOHALXC_TOOLDIR=$KOHALXC_TOOLDIR"

KOHALXC_DATADIR="${KOHALXC_DATADIR:=$KOHALXC_WORKS/$KOHALXC_ORGANIZATION/kohadata}"
#KOHALXC_DATASET="${KOHALXC_DATASET:=Axiell-20161019-Lappi_PallasPro}"
echo && echo "== KOHALXC_DATADIR=$KOHALXC_DATADIR"
echo "== KOHALXC_DATASET=$KOHALXC_DATASET"

KOHALXC_DATASET_DUMPPREFIX=dump4mmt
KOHALXC_DATASET_DUMP=$KOHALXC_DATASET_DUMPPREFIX-$KOHALXC_DATASET
echo && echo "== KOHALXC_DATASET_DUMPPREFIX=$KOHALXC_DATASET_DUMPPREFIX"
echo "== KOHALXC_DATASET_DUMP=$KOHALXC_DATASET_DUMP"

## Check that we have proper dataenv for building files..
[[ -z "$KOHALXC_DATASET" ]] && echo "== Error: no KOHALXC_DATASET defined.. exiting." && echo && exit 2
[[ ! -d "$KOHALXC_DATADIR/$KOHALXC_DATASET_DUMP" ]] && echo "== Error: $KOHALXC_DATADIR/KOHALXC_DATASET_DUMP not found.. exiting." && echo && exit 2

## Just for verbosity 
#(echo && cd $KOHALXC_DATADIR/$KOHALXC_DATASET_DUMP &&  pwd && ls -l)

## Make sure directories exist for these DATASET fixes/edits
mkdir -vp $KOHALXC_DATADIR/$KOHALXC_DATASET_DUMP/source/{TranslationTables,preprocessed,scripts,target}

echo
SOURCES_DIR="${KOHALXC_DATADIR}/${KOHALXC_DATASET_DUMP}/source/TranslationTables"
pwd && (cd $SOURCES_DIR && pwd && ls -l)

##################
## Do the stuff ##
##################

## Settings: names and paths
PM_NAME="${SRC_NAME:=liqlocde_translation}"
PM_HEAD="${PM_NAME}.header"
PM_TAIL="${PM_NAME}.tail"

#rm -f libid.tmp

# Construct tables from each csv found
echo && echo "== Generating map of PM_NAME=$PM_NAME in '$SOURCES_DIR'"
rm -f ${SOURCES_DIR}/$PM_NAME.pm-map 
pmtempfile="$(date +%s).tmp"
fileid=0
#for file in $(echo sources/*.csv); do
for file in ${SOURCES_DIR}/${PM_NAME}-*.csv; do
  #echo "Procssing $file"
  #test -e libid.tmp && libid="$(cat libid.tmp)" || libid="0"
  fileid=$(($fileid + 1))
  # Why doesn't >> work here??????
  #./conversion_table_constructor.sh $file $(($libid + 1)) > $pmtempfile.$libid
  #./liqlocdeConstructor.sh $file > $pmtempfile.$fileid
  #${KOHALXC_TOOLDIR}/ppmmtws/tools/liqlocdeConstructor.sh $file > /tmp/$pmtempfile.$fileid
  ./liqlocdeConstructor.sh $file > /tmp/$pmtempfile.$fileid
  cat /tmp/$pmtempfile.$fileid
done > ${SOURCES_DIR}/$PM_NAME.pm-map 
rm -f /tmp/$pmtempfile.*

## Create a perl module out of constructed tables
#cat $PM_HEAD $pmtempfile.* $PM_TAIL > ${PM_NAME}.pm
#(cd $SOURCES_DIR && cat ${PM_HEAD} ${PM_NAME} ${PM_TAIL} > ${PM_NAME}.pm && rm $PM_NAME)

## Copy to ../PerlMMT/TranslationTables/.
cp -vp ${SOURCES_DIR}/$PM_NAME.pm-map ../PerlMMT/TranslationTables/.

echo "== Done: ${PM_NAME}.pm-map created and copied to $(pwd)/../PerlMMT/TranslationTables/."

exit 0
