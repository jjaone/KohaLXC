#!/usr/bin/perl
package PatronsImportChain::SsnToSsnStore;

use Modern::Perl;
use threads;
use threads::shared;

our $nextIndex :shared;
our $firstRun :shared;
$nextIndex = 0;
$firstRun = 1;

our %ssns :shared; #Store key - ssn pairs so we can deduplicate them!

sub beginINSERTBatch {
    my ($file, $firstFreeSSNStoreIndex) = @_;
    $nextIndex = $firstFreeSSNStoreIndex;

    open(my $batch, ">:encoding(UTF-8)", $file) or die "Can't open $file for Ssn batch";

    print $batch 'INSERT INTO ssn (ssnkey, ssnvalue) VALUES '."\n";

    return $batch;
}

sub appendValues {
    my ($batch, $ssnvalue) = @_;
    my $error;

    #Catch duplicate ssn's!!
    if (exists $ssns{$ssnvalue} ) {
        print "Duplicate SSN: $ssnvalue\n";
        return 'sotu'.$ssns{$ssnvalue};
    }
    
    my $ssnkey = _getIndex();
    
    if ($firstRun) {
        $firstRun = 0;
        print $batch "('$ssnkey', '$ssnvalue')\n";
    }
    else {
        print $batch ",('$ssnkey', '$ssnvalue')\n";
    }
    
    $ssns{$ssnvalue} = $ssnkey;
    
    return "sotu$ssnkey";
}

sub endINSERTBatch {
    my $batch = shift;
    
    print $batch ';';
    
    close $batch;
}

sub _getIndex {
    lock $nextIndex;
    return ++$nextIndex;
}

return 1;