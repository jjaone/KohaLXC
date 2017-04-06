#!/bin/bash

./import.pl ../configBiblios.xml   2&> logs/biblios.log
./import.pl ../configItem.xml      2&> logs/items.log
./import.pl ../configPatron.xml    2&> logs/patrons.log
./import.pl ../configCheckouts.xml 2&> logs/checkouts.log
./import.pl ../configHolds.xml     2&> logs/holds.log
./import.pl ../configFines.xml     2&> logs/fines.log
./import.pl ../configHistory.xml   2&> logs/history.log
