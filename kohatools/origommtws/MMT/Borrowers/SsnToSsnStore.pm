#!/usr/bin/perl
package MMT::Borrowers::SsnToSsnStore;

use Modern::Perl;
use threads;
use threads::shared;

our $nextIndex :shared;
our $firstRun :shared;
$nextIndex = 0;
$firstRun = 1;

our %ssns :shared; #Store key - ssn pairs so we can deduplicate them!
our $fh;

sub beginINSERTBatch {
    $nextIndex = $CFG::CFG->{Borrowers}->{firstFreeSSNStoreIndex};
    my $file = $CFG::CFG->{targetDataDirectory}.'ssnstore.sql';

    open($fh, ">:encoding(UTF-8)", $file) or die "Can't open $file for Ssn batch";

    print $fh "ssnkey, ssnvalue\n----------------";
}

sub appendValues {
    my ($ssnvalue) = @_;
    my $error;

    #Catch duplicate ssn's!!
    if (exists $ssns{$ssnvalue} ) {
        print "Duplicate SSN: $ssnvalue\n";
        return 'sotu'.$ssns{$ssnvalue};
    }

    if ($firstRun) {
        beginINSERTBatch();
    }

    my $ssnkey = _getIndex();

    if ($firstRun) {
        $firstRun = 0;
    }
    print $fh "$ssnkey,$ssnvalue\n";

    $ssns{$ssnvalue} = $ssnkey;

    return "sotu$ssnkey";
}

sub endINSERTBatch {
    close $fh;
}

sub _getIndex {
    lock $nextIndex;
    return ++$nextIndex;
}

return 1;
