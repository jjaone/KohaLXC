##Use this script to collect all the exported modules and send to the destination server.

cat Biblios/03_biblios.* > biblios.migrateme
cat Items/01_items0* > items.migrateme
cat Holds/01_holds0* > holds.migrateme
cat Patrons/01_patrons* > patrons.migrateme
cat CheckOuts/01_checkouts* > checkouts.migrateme
cat History/01_history* > history.migrateme
cat Fines/01_fine* > fines.migrateme
cat Serials/serialmothers.marc > serialmothers.migrateme
cat Serials/serials.marc > serials.migrateme
cat SerialItems/serials.item > serialItems.migrateme
tar -czf migrateme.tar.gz *.migrateme Patrons/ssn
scp migrateme.tar.gz kohapreproduction:/home/koha/migrateme.tar.gz
rm *.migrateme
