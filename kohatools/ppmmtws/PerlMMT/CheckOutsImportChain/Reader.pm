package CheckOutsImportChain::Reader;
use strict;
use warnings;
use utf8;

use CommonRoutines;
use CheckOutsImportChain::Instructions;
use Checkout;

my $print;
my $log;

my $checkoutsCount = 0;

sub new {
	my $class = shift;
	my $R = {};
	bless ($R, $class);
	
	$R->{instructions} = CheckOutsImportChain::Instructions::getInstructions();
	
	$log = LiteLogger->new({package => 'CheckOutsImportChain::Reader'});
	$print = LiteLogger->new({package => 'CheckOutsImportChain::Reader'});
	
	return $R;
}

sub setNewChunk {
    close $_[0]->{LILLOAN} if defined $_[0]->{LILLOAN};
    open($_[0]->{LILLOAN}, "<:utf8", $_[1]) or die $!.": ".$_[1]; #reads the patrons file
}
sub setThreadId {
    my $R = shift;
    $R->{threadId} = shift;
}

sub processChunk {
	
    my $R = shift; #$R equals $self, eg. CheckOutsImportChain::Reader
    
    my $startTime = time;
    $print->info('Thread '.$R->{threadId}.": Getting a new checkouts Chunk, feeling exited!");
    
    $R->{checkouts} = []; #delete previous checkouts.
    
	#Read the whole Chunk
	my $fh = $R->{LILLOAN};
    while (my $row = <$fh>) {
		
		my @lilloanCols = split '\t', $row;
		
		my $checkout = Checkout->new();

		#patrons are asynchronously pulled from $LILLOAN and saved when processed to $R->{patrons}->{$docId}
		my $instructions = $R->{instructions}->{'lilloan.kir'};
		
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
				    push @param, CommonRoutines::trim( $lilloanCols[$_] );
			    }
		    }
		    no strict 'refs';
		    my $functionName = 'set_'.$field;
		    $keepalive = $checkout->$functionName($R, \@param);
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
		
		push @{$R->{checkouts}}, $checkout;
		
    }
    
    $print->info('process Checkouts time elapsed : ' . ( ( time - $startTime ) ) . 'sec');
    
    if (@{$R->{checkouts}}) { #Check if we have a non-zero length hash.
		return $R->{checkouts};
    }
    return undef;
	
}

#make compiler happy! :D :D :D :D
1;