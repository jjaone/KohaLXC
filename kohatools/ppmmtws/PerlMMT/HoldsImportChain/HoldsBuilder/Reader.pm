package HoldsImportChain::HoldsBuilder::Reader;
use strict;
use warnings;
use utf8;

use CommonRoutines;
use HoldsImportChain::HoldsBuilder::Instructions;
use LiteLogger;

my $print;
my $log;

my $holdCount = 0;

sub new {
	my $class = shift;
	my $R = {};
	bless ($R, $class);

	$R->{instructions} = HoldsImportChain::HoldsBuilder::Instructions::getInstructions();

	$log = LiteLogger->new({package => 'HoldsImportChain::HoldsBuilder'});
	$print = LiteLogger->new({package => 'HoldsImportChain::HoldsBuilder'});
	
	return $R;
}

sub setNewChunk {
    close $_[0]->{LILRESRV} if defined $_[0]->{LILRESRV};
    open($_[0]->{LILRESRV}, "<:utf8", $_[1]) or die $!.": ".$_[1]; #reads the marc items file
}
sub setThreadId {
    my $R = shift;
    $R->{threadId} = shift;
}

sub processChunk {
	
	my $R = shift;
    
    my $startTime = time;
    $print->info('Thread '.$R->{threadId}.": Getting a new Holds Chunk, feeling exited!");
    
    $R->{holds} = {}; #delete previous items.
	
    my $fh = $R->{LILRESRV};
    while (my $row = <$fh>) {

		my @lilresrvCols = split '\t', $row;
		
		my $hold = Hold->new();

		#items are asynchronously pulled from $LICCOPY and saved when processed to $R->{items}->{$docId}
		my $instructions = $R->{instructions}->{'lilresrv.kir'};
		
		my $keepalive;
		
		foreach my $instruction ( @$instructions ) {
			my $field = $instruction->[0];
		
			my $sourceColumns = $instruction->[1]; #get the Array containing the source columns for this item field

			#Prepare PostProcessor parameters.
			my @param;
			if (! (ref $sourceColumns eq 'ARRAY')) {
				push @param, $sourceColumns; #if we didn't get an array, then we have a constant
			}
			else {
				foreach(@$sourceColumns) {
					push @param, CommonRoutines::trim( $lilresrvCols[$_] );
				}
			}
			no strict 'refs';
			my $functionName = 'set_'.$field;
			$keepalive = $hold->$functionName($R, \@param);
			use strict 'refs';
			
			#Skip this Item if it is marked as deleted! deleted should be checked as second in the instructions-file, just after the PRIMARY KEY
			#  this way we avoid a lot of unnecessary computation and error-logging
			if (defined $keepalive && $keepalive eq 'KILL MEE!') {
				last();
			}
		}
		#Part of the item skipping control structure.
		if (defined $keepalive && $keepalive eq 'KILL MEE!') {
		    next();
		}
		
		$R->{holds}->{$hold->get_id()} = $hold;
		
    }
    
    $print->info('getSliceTime elapsed : ' . ( ( time - $startTime ) ) . 'sec');
    
    if (%{$R->{holds}}) { #Check if we have any holds to write
		return 1;
    }
    return undef;
	
}

#make compiler happy! :D :D :D :D
1;