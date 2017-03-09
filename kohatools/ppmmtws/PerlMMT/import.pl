#! /usr/bin/perl

use strict;
use warnings;
use Carp;
use Cwd;

use lib "lib/";

use CommonRoutines;
use PreProcess::LoadExternalRepositories;
use BibliosImportChain::Controller;
use ItemsImportChain::Controller;
use HoldsImportChain::Controller;
use FinesImportChain::Controller;
use PatronsImportChain::Controller;
use CheckOutsImportChain::Controller;
use HistoryImportChain::Controller;

print "Current working directory: ".Cwd::getcwd."\n";

#### Start the program flow control ####
#print "One can reset all logs using\n   --resetlog\n";
if (defined $ARGV[0] && $ARGV[0] eq '--resetlog') {
    system('rm '.Cwd::getcwd.'/logs/*');
    print "**Logs reset**\n";
    exit 0;
}
if (defined $ARGV[0]) {
    {
        package CFG;
        our $CFG = CommonRoutines::readConfig($ARGV[0]);
    }
    print "**Config Read**\n";
}
else {
    print "ERROR! You must define the configuration file as the 1st command line parameter! \n Eg.> perl import.pl /home/kivilahtio/workspace/config.xml\n";
    exit 1;
}


printConversionNotes();


PreProcess::LoadExternalRepositories::load();

if ( $CFG::CFG->{OrgUnitsImportChain}->{RestoreBackup} ) {
    OrgUnitsImportChain::DatabaseBackupRestorer::restore();
}
if ( $CFG::CFG->{OrgUnitsImportChain}->{TakeBackup} ) {
    OrgUnitsImportChain::DatabaseBackupRestorer::takeBackup();
}

if ($CFG::CFG->{'BibliosImportChain'}->{'doRun'}) {
    BibliosImportChain::Controller::start();
}
    
if ($CFG::CFG->{'ItemsImportChain'}->{'doRun'}) {
    ItemsImportChain::Controller::start();
}

if ($CFG::CFG->{'HoldsImportChain'}->{'doRun'}) {
    HoldsImportChain::Controller::start();
}

if ($CFG::CFG->{'FinesImportChain'}->{'doRun'}) {
    FinesImportChain::Controller::start();
}

if ($CFG::CFG->{'PatronsImportChain'}->{'doRun'}) {
    PatronsImportChain::Controller::start();
}

if ($CFG::CFG->{'CheckOutsImportChain'}->{'doRun'}) {
    CheckOutsImportChain::Controller::start();
}

if ($CFG::CFG->{'HistoryImportChain'}->{'doRun'}) {
    HistoryImportChain::Controller::start();
}


sub printConversionNotes {
    if ($CFG::CFG->{organization} eq 'pielinen') {
        print <<HELP;
Making the Pielinen conversion. Please remember to set the following Koha administrative entities:

    +============+
   ||New branches||
    +============+
    NUR_NUR
    NUR_NURAU
    LIE_LIE
    LIE_LAKO - Kolin etätoimipiste. Kolin siirtokokoelma. Ei varaukset tartu.
    LIE_LIEAU
    ILO_ILO
    ILO_ILOAU
    --ILO_LATER - Laitoskirjasto Terveysasema, This is removed during the migration
    ILO_LUK - Lukio

    +======================+
   ||New shelving locations||
    +======================+
    ARK - Arkisto

    +=======================+
   ||New borrower categories||
    +=======================+

    +========================+
   ||New itemtypes categories||
    +========================+
    CA - Celia äänikirja

    +=====================+
   ||New systempreferences||
    +=====================+
    OpacHiddenItems:    itype: [CA]


HELP
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        #
    }
    else {
        cluck("No such organization ".$CFG::CFG->{organization}." mapped!");
    }
}
