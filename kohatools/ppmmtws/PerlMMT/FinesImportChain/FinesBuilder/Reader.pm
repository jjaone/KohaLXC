package FinesImportChain::FinesBuilder::Reader;
use strict;
use warnings;
use utf8;

use CommonRoutines;
use FinesImportChain::FinesBuilder::Instructions;
use LiteLogger;

my $print;
my $log;

my $fineCount = 0;

sub new {
	my $class = shift;
	my $R = {};
	bless ($R, $class);

	$R->{instructions} = FinesImportChain::FinesBuilder::Instructions::getInstructions();
	
	$log = LiteLogger->new({package => 'FinesImportChain::FinesBuilder'});
	$print = LiteLogger->new({package => 'FinesImportChain::FinesBuilder'});
	
	return $R;
}

sub setNewChunk {
    close $_[0]->{LILCDEBT} if defined $_[0]->{LILCDEBT};
    open($_[0]->{LILCDEBT}, "<:utf8", $_[1]) or die $!.": ".$_[1]; #reads the marc items file
}
sub setThreadId {
    my $R = shift;
    $R->{threadId} = shift;
}

sub processChunk {
	
	my $R = shift;
    
    my $startTime = time;
    $print->info('Thread '.$R->{threadId}.": Getting a new Fines Chunk, feeling exited!");
    
    $R->{fines} = {}; #delete previous items.
	my $fineIndex = 0; #Because there is no primary key for lilcdebt-table, but because the ItemWriter expects a hash, we must generate hash keys somehow. Using simple order of appearance in the fines chunk.
	
    my $fh = $R->{LILCDEBT};
    while (my $row = <$fh>) {
		$fineIndex++;

		my @lilcdebtCols = split '\t', $row;
		
		my $fine = Fine->new();

		#items are asynchronously pulled from $LICCOPY and saved when processed to $R->{items}->{$docId}
		my $instructions = $R->{instructions}->{'lilcdebt.kir'};
		
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
					push @param, CommonRoutines::trim( $lilcdebtCols[$_] );
				}
			}
			no strict 'refs';
			my $functionName = 'set_'.$field;
			$keepalive = $fine->$functionName($R, \@param);
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
		
		$R->{fines}->{$fineIndex} = $fine;
		
    }
    
    $print->info('getSliceTime elapsed : ' . ( ( time - $startTime ) ) . 'sec');
    
    if (%{$R->{fines}}) { #Check if we have any fines to write
		return 1;
    }
    return undef;
	
}

#make compiler happy! :D :D :D :D
1;