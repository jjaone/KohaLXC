package PatronsImportChain::Controller;

use warnings;
use strict;
use utf8;
#use diagnostics;
use threads;
use threads::shared;

use PatronsImportChain::Reader;
use PatronsImportChain::SsnToSsnStore;
use PreProcess::PreProcess;
use ChunkDealer;
use ItemWriter;
use LiteLogger;

my $sourceDataDirectory;
my $patronsWriter;
my $chunker :shared;
my $ssnbatch; #Write the ssn INSERT statement here for the ssn-store

my $print;

my $threads = [];

sub init {

    $print = LiteLogger->new({package => 'PatronsImportChain::Controller'});
    Patron::initPackageVariables();

    #Load configuration variables
    $sourceDataDirectory = $CFG::CFG->{'sourceDataDirectory'};

    ##Run the PreProcessor if requested, or if preprocessed files are not found.
    my $firstLilcustChunk = $sourceDataDirectory.'/preprocessed/lilcust.kir.chunks/lilcust.kir0000';
    if (! (-e $firstLilcustChunk) || $CFG::CFG->{PatronsImportChain}->{PreProcess}) {
        print "\nNOTE: Preprocessing source files because no preprocessed source files found in '$firstLilcustChunk'.\n" if ! (-e $firstLilcustChunk);
        PreProcess::PreProcess::run(package => 'PatronsImportChain');
    }

    #Init the ChunkDealer to provide licmarca-chunks for threads to process
    $chunker = ChunkDealer->new($sourceDataDirectory.'/preprocessed/lilcust.kir.chunks/lilcust.kir',
                                           $CFG::CFG->{StartingChunk},
                                           $CFG::CFG->{EndingChunk});


    #make sure the destination folder exists    
    system('mkdir -p '.$CFG::CFG->{'targetDataDirectory'}.'/Patrons/');
    $patronsWriter = ItemWriter->new($CFG::CFG->{'targetDataDirectory'}.'/Patrons/01_patrons');

    $ssnbatch = PatronsImportChain::SsnToSsnStore::beginINSERTBatch( $CFG::CFG->{'targetDataDirectory'}.'/Patrons/ssn', $CFG::CFG->{PatronsImportChain}->{FreeSSNStoreIndex} );
    print "\nInitializing the SSN Store writer using ".$CFG::CFG->{PatronsImportChain}->{FreeSSNStoreIndex}." as the starting index for new SSN-keys\nMake sure this key doesn't overlap with existing ssn-keys.\n";
}

sub start {
    
    my $startTime = time;
    
    init();
    
    $print->info('Starting patrons building');
    
    ###Start the business functionality.
    #Init the worker module. This contains all the authorities. This is replicated for each thread. Such is the way Perl's magic works. Sharing authorities effectively is impossible.
    my $patronsReader = PatronsImportChain::Reader->new( $ssnbatch );

    my $threadRoutine = sub { my $threadId = shift().'';
        if ( $CFG::CFG->{PatronsImportChain}->{BuildPatrons} ) {
            my ($chunk, $chunkSuffix) = $chunker->fetch($threadId);
			$patronsReader->setThreadId($threadId);

            #Thread-safely request a new chunk for the thread to process. Chunk == a unix-split:ted source file
            while ( $chunk ) {

				$patronsReader->setNewChunk($chunk);
				$patronsWriter->setNewChunk($chunkSuffix);

                $print->info('+Thread '.$threadId.': Processing chunk '.$chunkSuffix);
                

				$print->info('++Thread '.$threadId.': Reading patrons');

                while ( my $processedChunk = $patronsReader->processChunk() ) {
             
					$patronsWriter->writeItems($processedChunk);
				
					$print->info('Thread '.$threadId.': Freeing written patronSlice '.$chunkSuffix.' from memory');
					foreach my $key (keys %$processedChunk) {
						$processedChunk->{$key}->DESTROY();
					}
	      
                }

                ($chunk, $chunkSuffix) = $chunker->fetch($threadId);
            }
	    
            $print->info('+++Thread '.$threadId.': Exiting happily!');
        }
    };
    
    ### Threaded programming starts HERE ###
    #Initialize threads
    if ($CFG::CFG->{threadCount} > 0) {
	for my $i (0..$CFG::CFG->{threadCount}) {

	    $threads->[$i] = threads->create( $threadRoutine,$i );

	}
        #Keep monitoring thread status
		while (@$threads > 0) {
			for (my $ti=0 ; $ti<@$threads ; $ti++) {
				my $thread = $threads->[$ti];
				# Check thread's state
			    if ($thread->is_running()) {
				    sleep(5);
			    }
			    if ($thread->is_joinable()) {
				    $thread->join();
				    splice @$threads, $ti, 1;
			    }
		    }	
		}
    } ##EO Threaded programming
    ### Synchronous programming HERE ###
    else {
	&$threadRoutine($CFG::CFG->{threadCount});
    }## EO Synhronous programming
    
	PatronsImportChain::SsnToSsnStore::endINSERTBatch( $ssnbatch );
	
    $print->info('Patrons processed in ',((time-$startTime)/60),'minutes.');
}

#Make compiler happy
1;