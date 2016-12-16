#!/bin/bash

KOHALXC_DATASET_FIXSCRIPT=source/scripts/fix_source.sh
KOHALXC_DATASET_FIXSOURCE=source.fix_biblios
echo "== KOHALXC_DATASET_FIXSCRIPT=$KOHALXC_DATASET_FIXSCRIPT" 
echo "== KOHALXC_DATASET_FIXSOURCE=$KOHALXC_DATASET_FIXSOURCE"

KOHALXC_DATADIR="${KOHALXC_DATADIR:=$KOHALXC_WORKS/$KOHALXC_ORGANIZATION/kohadata}"
KOHALXC_DATASET=Axiell-20161019-Lappi_PallasPro
echo 
echo "== KOHALXC_DATADIR=$KOHALXC_DATADIR"
echo "== KOHALXC_DATASET=$KOHALXC_DATASET"

KOHALXC_DATASET_DUMPPREFIX=dump4mmt
KOHALXC_DATASET_DUMP=$KOHALXC_DATASET_DUMPPREFIX-$KOHALXC_DATASET
echo
echo "== KOHALXC_DATASET_DUMPPREFIX=$KOHALXC_DATASET_DUMPPREFIX"
echo "== KOHALXC_DATASET_DUMP=$KOHALXC_DATASET_DUMP"

(cd $KOHALXC_DATADIR/$KOHALXC_DATASET_DUMP &&  pwd && ls -l)

## Make sure directories exist for DATASET fixes/edits
mkdir -vp $KOHALXC_DATADIR/$KOHALXC_DATASET_DUMP/$KOHALXC_DATASET_FIXSOURCE/{preprocessed,scripts,target}

echo
cd $KOHALXC_DATADIR/$KOHALXC_DATASET_DUMP/$KOHALXC_DATASET_FIXSOURCE && pwd || exit 666


################
## Do the fix ##
################

## Sync/Copy original sources here
echo && echo "== Sync/copy source *.kir files here.."
pwd && echo "rsync -avh --include '*/' --include '*.kir' --exclude  '*' --delete --force --delete-excluded --prune-empty-dirs ../source/ ./"
rsync -avh --include '*/' --include '*.kir' --exclude  '*' --delete --force --delete-excluded --prune-empty-dirs ../source/ ./
ls -lR

## Ensure directories exist for DATASET fixes/edits (maybe rsynce removed some of these)
mkdir -vp $KOHALXC_DATADIR/$KOHALXC_DATASET_DUMP/$KOHALXC_DATASET_FIXSOURCE/{preprocessed,scripts,target}

## Fix licmarca.kir:

# - split to 36631 long chunkcs
echo && echo "== Splitting licmarca.kir to 36631 lines long chunks.."
mkdir -vp .splitted-biblios
(cd .splitted-biblios && rm -f *-* && 
split -a 3 -d -l 36631 ../licmarca.kir licmarca.kir- &&
file licmarca.kir-*)

echo && echo "== Ignoring first chunk to combine chunks to 'licmarca.kir-fixed'"
rm .splitted-biblios/licmarca.kir-000
rm -f licmarca.kir-fixed

echo "== Combine ok chunks to 'licmarca.kir-fixed'.."
cat .splitted-biblios/licmarca.kir-* >> licmarca.kir-fixed

echo "== Backup original licmarca.kir (unless orig exists or is a symlink).."
[[ ! -e licmarca.kir-orig ]] && [[ ! -L licmarca.kir ]] && mv licmarca.kir licmarca.kir-orig

echo "== Rename fix to 'licmarca.kir'.."
[[ -e licmarca.kir-fixed ]] && mv licmarca.kir-fixed licmarca.kir
echo "== Symlink fix to 'licmarca.kir'.."
#[[ -e licmarca.kir-fixed ]] && ln -s licmarca.kir-fixed licmarca.kir

## Fix licmarcb.kir: truncate to zero size
echo "== Truncate licmarcb.kir to zero size (backup original).."
[[ ! -e licmarcb.kir-orig ]] && [[ ! -L licmarcb.kir ]] && mv licmarcb.kir licmarcb.kir-orig
truncate --size=0 licmarcb.kir

## Show what we got
ls -lR

## All done
exit 0
