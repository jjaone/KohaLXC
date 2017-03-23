package PatronsImportChain::Reader;
use strict;
use warnings;
use utf8;

use CommonRoutines;
use PatronsImportChain::Instructions;
use Patron;
use LiteLogger;

my $print;

sub new {
	my $class = shift;
	my $ssnbatch = shift;
	my $R = {};
	bless ($R, $class);
	
#	$R->{huoltaja} = Repository::SingletonRepository->createRepository(
#			filePath => $CFG::CFG->{'sourceDataDirectory'}.'/preprocessed/huoltaja.kir',
#			pk => 0,
#			logger => 'PatronsImportChain::huoltaja');
	$R->{liwcuset} = Repository::AuthoritiesRepository->createRepository(
			filePath => $CFG::CFG->{'sourceDataDirectory'}.'/preprocessed/liwcuset.kir',
	 		pk => 0,
	 		columns => [1,'email',2,'gsm'],
			logger => LiteLogger->new({package => 'PatronsImportChain::Reader'}) );
	
	$R->{instructions} = PatronsImportChain::Instructions::getInstructions();
	
	$R->{ssnbatch} = $ssnbatch;
	
	$print = LiteLogger->new({package => 'PatronsImportChain::Reader'});
	
	return $R;
}

sub setNewChunk {
    close $_[0]->{LILCUST} if defined $_[0]->{LILCUST};
    open($_[0]->{LILCUST}, "<:utf8", $_[1]) or die $!.": ".$_[1]; #reads the patrons file
}
sub setThreadId {
    my $R = shift;
    $R->{threadId} = shift;
}

sub processChunk {
	
    my $R = shift;
    
    my $startTime = time;
    $print->info('Thread '.$R->{threadId}.": Getting a new Patrons Chunk, feeling exited!");
    
    $R->{patrons} = {}; #delete previous patrons.
	my $patronCount = 0;
	my $removedPatronsCount = 0;
    
	my $fh = $R->{LILCUST};
    while (my $row = <$fh>) {
		
		my @lilcustCols = split '\t', $row;
		
		my $patron = Patron->new();

		#patrons are asynchronously pulled from $LILCUST and saved when processed to $R->{patrons}->{$docId}
		my $instructions = $R->{instructions}->{'lilcust.kir'};
		
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
				    push @param, CommonRoutines::trim( $lilcustCols[$_] );
			    }
		    }
		    no strict 'refs';
		    my $functionName = 'set_'.$field;
		    $keepalive = $patron->$functionName($R, \@param);
		    use strict 'refs';
		    
		    #Skip this patron if it is marked as deleted! deleted should be checked as second in the instructions-file, just after the PRIMARY KEY
		    #Also patrons with family_name as POISTETTU, are removed
		    #  this way we avoid a lot of unnecessary computation and error-logging
		    if (defined $keepalive && $keepalive eq 'KILL MEE!') {
				$removedPatronsCount++;
			    last();
		    }
		}
		#Part of the patron skipping control structure.
		if (defined $keepalive && $keepalive eq 'KILL MEE!') {
		    next();
		}
		
		$R->{patrons}->{$patron->get_borrowernumber()} = $patron;
		$patronCount++;
		
    }
    
    $print->info('getSliceTime elapsed : ' . ( ( time - $startTime ) ) . 'sec. Removed '.$removedPatronsCount.'/'.$patronCount);
    
    if (%{$R->{patrons}}) { #Check if we have a non-zero length hash.
		return $R->{patrons};
    }
    return undef;
	
}

#make compiler happy! :D :D :D :D
1;