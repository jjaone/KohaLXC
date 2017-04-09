package HoldsImportChain::Controller;

use warnings;
use strict;
use utf8;

use HoldsImportChain::HoldsBuilder::Instructions;
use HoldsImportChain::HoldsBuilder::Reader;
use PreProcess::PreProcess;
use ChunkDealer;
use Hold;
use ItemWriter;
use LiteLogger;

my $liccopyi;

my $instructions;

my $log;
my $print;
my $chunker :shared; #gives new liccopy chunks for threads to digest.
my $holdsWriter;
my $serialWriter;

my $threads = [];

my $sourceDataDirectory;
my $openedSourceStreams;

sub init {
	
	$print = LiteLogger->new({package => 'HoldsImportChain::Controller'});
	$log = LiteLogger->new({package => 'HoldsImportChain::Controller'});
	Hold::initPackageVariables();
	
	$sourceDataDirectory = $CFG::CFG->{'sourceDataDirectory'};
	
	##Run the PreProcessor if requested, or if preprocessed files are not found.
	my $firstLiccopyChunk = $sourceDataDirectory.'/preprocessed/lilresrv.kir.chunks/lilresrv.kir0000';
	if (! (-e $firstLiccopyChunk) || $CFG::CFG->{HoldsImportChain}->{PreProcess}) {
	    print "\nNOTE: Preprocessing source files because no preprocessed source files found in '$firstLiccopyChunk'.\n" if ! (-e $firstLiccopyChunk);
	    PreProcess::PreProcess::run(package => 'HoldsImportChain');
	}
	
    #Load configuration variables
    $sourceDataDirectory = $CFG::CFG->{'sourceDataDirectory'};
    
    #Init the ChunkDealer to provide liccopy-chunks for threads to process
    $chunker = ChunkDealer->new($sourceDataDirectory.'/preprocessed/lilresrv.kir.chunks/lilresrv.kir',
                                           $CFG::CFG->{StartingChunk},
                                           $CFG::CFG->{EndingChunk});
	
	#make sure the destination folder exists    
    system('mkdir -p '.$CFG::CFG->{'targetDataDirectory'}.'/Holds/');
	$holdsWriter = ItemWriter->new($CFG::CFG->{'targetDataDirectory'}.'/Holds/01_holds');
}

sub start {
    
    my $startTime = time;
    
	init();

	$print->info('Starting Holds building');
										   
										   
	###Start the business functionality.
    #Init the worker module. This contains all the authorities. This is replicated for each thread. Such is the way Perl's magic works. Sharing authorities effectively is impossible.
    my $holdsReader = HoldsImportChain::HoldsBuilder::Reader->new();
    
    my $perlSize = [];
    my $threadRoutine = sub { my $threadId = shift().'';
        if ( $CFG::CFG->{HoldsImportChain}->{BuildHolds} ) {
            
            my ($chunk, $chunkSuffix) = $chunker->fetch($threadId);
			$holdsReader->setThreadId($threadId);
            
            #Thread-safely request a new chunk for the thread to process. Chunk == a unix-split:ted source file
            while ( $chunk ) {
				
				$holdsReader->setNewChunk($chunk);
				$holdsWriter->setNewChunk($chunkSuffix);

                $print->info('+Thread '.$threadId.': Processing chunk '.$chunkSuffix);
                

				$print->info('++Thread '.$threadId.': Reading holds');
                
                #get a biblio slice. Slice == part of a chunk read to memory and processed to the internal memory model (MARC::Record).
                while ( $holdsReader->processChunk() ) {
					my $holdSlice = $holdsReader->{holds};
                
					$holdsWriter->writeItems($holdSlice);
		                        
					$print->info('Thread '.$threadId.': Freeing written Hold Chunk '.$chunkSuffix.' from memory');
					foreach my $key (keys %$holdSlice) {
						$holdSlice->{$key}->DESTROY();
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
	
    $print->info('Items processed in ',((time-$startTime)/60),'minutes.');




}
#run(0,0,0,0,"../../../../PallasProDumps/");
return 1; #to make compiler happy!