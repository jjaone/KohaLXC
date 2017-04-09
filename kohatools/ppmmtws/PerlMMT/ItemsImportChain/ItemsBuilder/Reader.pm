package ItemsImportChain::ItemsBuilder::Reader;
use strict;
use warnings;
use utf8;

use CommonRoutines;
use Repository::AuthoritiesRepository;
use Repository::HashRepository;
use Repository::MarcRepository;
use ItemsImportChain::ItemsBuilder::Instructions;
use LiteLogger;

my $print;
my $log;

my $itemCount = 0;

sub new {
	my $class = shift;
	my $R = {};
	bless ($R, $class);
	
	$R->{liccopyi} = Repository::HashRepository->createRepository(
			filePath => $CFG::CFG->{'sourceDataDirectory'}.'/preprocessed/liccopyid.kir',
			pk => 0,
			column => 1,
			logger => LiteLogger->new({package => 'ItemsImportChain::ItemsBuilder'}) );
	$R->{liccnote} = Repository::HashRepository->createRepository(
			filePath => $CFG::CFG->{'sourceDataDirectory'}.'/preprocessed/liccnote.kir',
			pk => 0,
			column => 2,
			logger => LiteLogger->new({package => 'ItemsImportChain::ItemsBuilder'}) );
	$R->{licauthmarc} = Repository::MarcRepository->createRepository(
			filePath => $CFG::CFG->{'sourceDataDirectory'}.'/preprocessed/licauthmarc.repo',
			logger => LiteLogger->new({package => 'ItemsImportChain::ItemsBuilder'}) );
	$R->{liltrans} = Repository::AuthoritiesRepository->createRepository( #catch rotating collections/items
			filePath => $CFG::CFG->{'sourceDataDirectory'}.'/preprocessed/liltrans.kir',
	 		pk => 2, #trcopynew, the new barcode gained during rotation
	 		columns => [5,'locidold',7,'depidold',9,'date'],
			logger => LiteLogger->new({package => 'PatronsImportChain::Reader'}) );
	
	$R->{instructions} = ItemsImportChain::ItemsBuilder::Instructions::getInstructions();
	
	$log = LiteLogger->new({package => 'ItemsImportChain::ItemsBuilder'});
	$print = LiteLogger->new({package => 'ItemsImportChain::ItemsBuilder'});
	
	return $R;
}

sub setNewChunk {
    close $_[0]->{LICCOPY} if defined $_[0]->{LICCOPY};
    open($_[0]->{LICCOPY}, "<:utf8", $_[1]) or die $!.": ".$_[1]; #reads the marc items file
}
sub setThreadId {
    my $R = shift;
    $R->{threadId} = shift;
}

sub processChunk {
	
	my $R = shift;
    
    my $startTime = time;
    $print->info('Thread '.$R->{threadId}.": Getting a new Items Chunk, feeling exited!");
    
    $R->{items} = {}; #delete previous items.
	$R->{serials} = {}; #delete previous serials.
	
    my $fh = $R->{LICCOPY};
    while (my $row = <$fh>) {

		my @liccopyCols = split '\t', $row;
		
		my $item = Item->new();

		#items are asynchronously pulled from $LICCOPY and saved when processed to $R->{items}->{$docId}
		my $instructions = $R->{instructions}->{'liccopy.kir'};
		
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
					push @param, CommonRoutines::trim( $liccopyCols[$_] );
				}
			}
			no strict 'refs';
			my $functionName = 'set_'.$field;
			$keepalive = $item->$functionName($R, \@param);
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
		
		if ($item->{isASerial}) { #We need to separate serials from other items as they are processed in their own SerialsMigrationChain
			$R->{serials}->{$item->get_itemnumber()} = $item;
		}
		else {
			$R->{items}->{$item->get_itemnumber()} = $item;
		}
    }
    
    $print->info('getSliceTime elapsed : ' . ( ( time - $startTime ) ) . 'sec');
    
    if (%{$R->{items}} || %{$R->{serials}}) { #Check if we have any serials or items to write.
		return 1;
    }
    return undef;
	
}

#make compiler happy! :D :D :D :D
1;