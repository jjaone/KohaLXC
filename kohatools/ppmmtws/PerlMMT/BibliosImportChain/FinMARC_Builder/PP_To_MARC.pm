## ! IN THIS FILE ! ##
#-This file controls the reading of source bibliographic and holdings data, and creating a internal MARC-representation of it.
#-Threads are terminated when the desired Batchcount has been met. This is done when a thread requests more MARC data in readLicmarcaRow().
#-This file directs all the preprocessing and data massage operations prior to entering USEMARCON.
#-This file directs the writing to file.
#-This file controls all the operating threads and their access to shared resources.

package BibliosImportChain::FinMARC_Builder::PP_To_MARC;

use warnings;
use strict;
#use diagnostics;
use threads;
use threads::shared;
use utf8;

use POSIX qw(ceil);

use MARC::Record;
use Repository::AuthoritiesRepository;
use Repository::liccopy_undeleted;
use BibliosImportChain::FinMARC_Builder::BuildMARC;
use BibliosImportChain::FinMARC_Builder::SharedDocidRecordsHandler;
use Ontologiat::Asiasanat;

my $print;

my $nextFreeDocid :shared;

=head
use Data::Dumper;
use Injector;
use MarcXChange;
use IO::File;
use MarcRepair;
use StatusResolver;
=cut

sub new {
    my $class = shift;
    my $t; #is like $self
    $print = LiteLogger->new({package => 'BibliosImportChain.PP_To_MARC'});

    #Package variables
    $t->{threadId} = shift;
    
    $t->{prevDocId} = 0; #Used to notice when we go out of SliceRange and we should clear memory.
    
    $t->{records} = {}; #stores all the records here
    #$t->{componentPartHandler} = BibliosImportChain::FinMARC_Builder::ComponentPartHandler::init($t); #stores all unlinked component parts here and enforces linkings
    BibliosImportChain::FinMARC_Builder::SharedDocidRecordsHandler::init($t); #stores all unlinked component parts here and enforces linkings
    BibliosImportChain::FinMARC_Builder::BuildMARC::init();
    $nextFreeDocid = share $CFG::CFG->{BibliosImportChain}->{NextFreeDocId}; #stores the value of the highest docid found from LICMARCA, used to mark to where component parts can be appended to.
    #EO Package variable introduction
    
    #Init file streams
    $t->{sourceDataDirectory} = $CFG::CFG->{'sourceDataDirectory'};
    
    # $LICMARCA (the source chunk input stream) is opened at setNewChunk()
    $t->{licmarca_lock} = 0;
    #EO file stream init
    
    #Load Repositories
	#REMOVE ONKI $t->{onki} = Ontologiat::Asiasanat->init($CFG::CFG->{sourceDataDirectory});
	#REMOVE ONKI $t->{onki}->process_downloaded_files();
	$t->{liccopy} = Repository::liccopy_undeleted->createRepository(
            filePath => "$t->{sourceDataDirectory}/preprocessed/liccopy.kir",
            pk => 0,
            columns => [16], #the status1 so we can check if the copy is deleted or not
            logger => 'DatabaseRepository::liccopy');
	$t->{liccopyloc} = Repository::AuthoritiesRepository->createRepository(
            filePath => "$t->{sourceDataDirectory}/preprocessed/liccopy.kir",
            pk => 0,
            columns => [3,'homeloc',4,'homedep'],
            logger => 'DatabaseRepository::liccopyloc');
    $t->{licauthp} = Repository::AuthoritiesRepository->createRepository(
			filePath => "$t->{sourceDataDirectory}/preprocessed/licauthp.kir",
	 		pk => 0,
	 		columns => [1,'a',2,'h'],
			logger => LiteLogger->new({package => 'BibliosImportChain.PP_To_MARC.licauthp'}) );
    $t->{licauthc} = Repository::AuthoritiesRepository->createRepository(
			filePath => "$t->{sourceDataDirectory}/preprocessed/licauthc.kir",
	 		pk => 0,
	 		columns => [2,'a'],
			logger => LiteLogger->new({package => 'BibliosImportChain.PP_To_MARC.licauthc'}) );
    $t->{licauths} = Repository::AuthoritiesRepository->createRepository(
			filePath => "$t->{sourceDataDirectory}/preprocessed/licauths.kir",
	 		pk => 0,
	 		columns => [2,'a'],
			logger => LiteLogger->new({package => 'BibliosImportChain.PP_To_MARC.licauths'}) );
    $t->{licinfoa} = Repository::AuthoritiesRepository->createRepository(
			filePath => "$t->{sourceDataDirectory}/preprocessed/licinfoa.kir",
	 		pk => [0,1],
			   #06 => Type of record, 07 => Bibliographic level, 17 => Encoding level
	 		columns => [11,'06', 12,'07', 8,'17',9,'008_kohderyhma'],
			logger => LiteLogger->new({package => 'BibliosImportChain.PP_To_MARC.licinfoa'}) ); #kohderyhmä merkitään marc 008, paikka 22:ssa.
	$t->{licinfoi} = Repository::HashRepository->createRepository(
			filePath => $CFG::CFG->{'sourceDataDirectory'}.'/preprocessed/licinfoid.kir',
			pk => 3,
			column => 2,
			logger => LiteLogger->new({package => 'BibliosImportChain.PP_To_MARC.licinfoi'}) );
    #EO Repository loading

    bless($t, $class);
    
    return $t;
}

sub processChunk {
    my $t = shift;
    
    my $startTime = time;
    $print->info('Thread '.$t->{threadId}.": Processing a new chunk, feeling exited!");
    
    $t->{records} = {}; #delete previous records.
    
    my $sliceCounter = $t->{sliceIncrement};
    
	#We read all the licmarca rowsin this Chunk
	my $LICMARCA = $t->{LICMARCA};
    while (my $row = <$LICMARCA>) {
		#records are asynchronously pulled from $LICMARCA and saved after processing to $t->{records}->{$docId}
		BibliosImportChain::FinMARC_Builder::BuildMARC::buildCoreData($t, $row);
    }
    
    #During record creation component parts are collected to $t->{componentPartHandler}. This object can asynchronously process component parts and store child component parts to $t->{records}
    BibliosImportChain::FinMARC_Builder::SharedDocidRecordsHandler::linkSharedRecords();
    
    for my $docId ( keys %{$t->{records}} ) {
		BibliosImportChain::FinMARC_Builder::BuildMARC::buildComplexData( $t, $t->{records}->{$docId} );
    }
    
    $print->info('processChunk time elapsed : ' . ( ( time - $startTime ) ) . 'sec');
    
    if (%{$t->{records}}) { #Check if we have a non-zero length hash.
		return $t->{records};
    }
    return undef;
}
sub destruct {
    my $t = shift;

    close $t->{LICMARCA};
}
sub writeToMARCXMLFile {
    #lock $_[0]->{marcxml_lock};

    my $MARCXML = $_[0]->{MARCXML};
    print $MARCXML $_[1];
}
#Used to take n numbers from highestDocId for component parts in ComponentPartHandler. This is more thread friendly approach than reading and setting it.
sub reserveFreeDocIds {
    lock $nextFreeDocid;
    
    return $$nextFreeDocid += $_[1]; 
}
sub storeRecord {
    #lock $_[0]->{records};

    my $record = $_[1];
    $_[0]->{records}->{$record->docId} = $record;
}
sub findRecord {
    #lock $_[0]->{records};

    return $_[0]->{records}->{$_[1]};
}
sub removeRecord {
    #lock $_[0]->{records};

    $_[0]->{records}->{$_[1]}->DESTROY();
    delete $_[0]->{records}->{$_[1]};
}
#Insted of completely removing and obliterating a Record, we need to release it from this $PP_To_MARC->{record} to be used elsewhere.
sub releaseRecord {
    #lock $_[0]->{records};

    delete $_[0]->{records}->{$_[1]};
}
sub setNewChunk {
    close $_[0]->{LICMARCA} if defined $_[0]->{LICMARCA};
    open($_[0]->{LICMARCA}, "<:utf8", $_[1]) or die $!.": ".$_[1]; #reads the marc records file
}
sub setThreadId {
    my $self = shift;
    $self->{threadId} = shift;
}
#EO Resource accessors

	
	#ItemsInjector::Injector->run($biblios, $sliceStart, $sliceStop, $ARGV[3]); #$ARGV[3] is the directory from where ItemsInjector looks for source database dumps
	
	##Resolve the status and remove records marked as deleted where no copies are found
	#StatusResolver::run($biblios);
	
	#MarcRepair->run($biblios, $ARGV[2]);
	
	#my $io = IO::File->new($ARGV[1], 'a');
	#MarcXChange->convert($biblios, $io);
	#$io->close();



#return 1 to make compiler happy! :D
1;
