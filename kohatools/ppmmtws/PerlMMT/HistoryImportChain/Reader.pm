package HistoryImportChain::Reader;
use strict;
use warnings;
use utf8;

use CommonRoutines;
use HistoryImportChain::Instructions;
use History;

my $print;
my $log;

my $historyCount = 0;

sub new {
	my $class = shift;
	my $R = {};
	bless ($R, $class);
	
	$R->{instructions} = HistoryImportChain::Instructions::getInstructions();
	
	$log = LiteLogger->new({package => 'HistoryImportChain::Reader'});
	$print = LiteLogger->new({package => 'HistoryImportChain::Reader'});
	
	return $R;
}

sub setNewChunk {
    close $_[0]->{LILLNHIST} if defined $_[0]->{LILLNHIST};
    open($_[0]->{LILLNHIST}, "<:utf8", $_[1]) or die $!.": ".$_[1]; #reads the patrons file
}
sub setThreadId {
    my $R = shift;
    $R->{threadId} = shift;
}

sub processChunk {
	
    my $R = shift; #$R equals $self, eg. CheckOutsImportChain::Reader
    
    my $startTime = time;
    $print->info('Thread '.$R->{threadId}.": Getting a new history Chunk, feeling exited!");
    
    $R->{history} = []; #delete previous checkouts.
    
	#Read the whole Chunk
	my $fh = $R->{LILLNHIST};
    while (my $row = <$fh>) {
		
		my @lilnhistCols = split '\t', $row;
		
		my $history = History->new();

		#patrons are asynchronously pulled from $LILLOAN and saved when processed to $R->{patrons}->{$docId}
		my $instructions = $R->{instructions}->{'lillnhis.kir'};
		
		my $keepalive;
		
		foreach my $instruction ( @$instructions ) {
		    my $field = $instruction->[0];
	    
		    my $sourceColumns = $instruction->[1]; #get the Array containing the source columns for this patron field
    
		    #Prepare PostProcessor parameters.
		    my @param;
		    if (! (ref $sourceColumns eq 'ARRAY')) {
			    push @param, $sourceColumns; #if we didn't get an array, then we have a constant
		    }
		    else {
			    foreach(@$sourceColumns) {
				    push @param, CommonRoutines::trim( $lilnhistCols[$_] );
			    }
		    }
		    no strict 'refs';
		    my $functionName = 'set_'.$field;
		    $keepalive = $history->$functionName($R, \@param);
		    use strict 'refs';
		    
		    #Skip this patron if it is marked as deleted! deleted should be checked as second in the instructions-file, just after the PRIMARY KEY
		    #Also patrons with family_name as POISTETTU, are removed
		    #  this way we avoid a lot of unnecessary computation and error-logging
		    if (defined $keepalive && $keepalive eq 'KILL MEE!') {
			    last();
		    }
		}
		#Part of the checkout skipping control structure.
		if (defined $keepalive && $keepalive eq 'KILL MEE!') {
		    next();
		}
		
		push @{$R->{history}}, $history;
		
    }
    
    $print->info('process History time elapsed : ' . ( ( time - $startTime ) ) . 'sec');
    
    if (@{$R->{history}}) { #Check if we have a non-zero length hash.
		return $R->{history};
    }
    return undef;
	
}

#make compiler happy! :D :D :D :D
1;