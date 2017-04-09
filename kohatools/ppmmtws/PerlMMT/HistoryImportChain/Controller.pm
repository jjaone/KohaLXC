package HistoryImportChain::Controller;

use warnings;
use strict;
#use diagnostics;
use threads;
use threads::shared;
use utf8;

use HistoryImportChain::Reader;
use PreProcess::PreProcess;
use ChunkDealer;
use ItemWriter;
use LiteLogger;

my $sourceDataDirectory;
my $writer;
my $chunker :shared;

my $print;

my $threads = [];

sub init {
    
    $print = LiteLogger->new({package => 'HistoryImportChain::Controller'});
    History::initPackageVariables();
    
    #Load configuration variables
    $sourceDataDirectory = $CFG::CFG->{'sourceDataDirectory'};
    
    ##Run the PreProcessor if requested, or if preprocessed files are not found.
    my $firstLillnhistChunk = $sourceDataDirectory.'/preprocessed/lillnhis.kir.chunks/lillnhis.kir0000';
    if (! (-e $firstLillnhistChunk) || $CFG::CFG->{HistoryImportChain}->{PreProcess}) {
        print "\nNOTE: Preprocessing source files because no preprocessed source files found in '$firstLillnhistChunk'.\n" if ! (-e $firstLillnhistChunk);
		PreProcess::PreProcess::run(package => 'HistoryImportChain');
    }
    
    #Init the ChunkDealer to provide licmarca-chunks for threads to process
    $chunker = ChunkDealer->new($sourceDataDirectory.'/preprocessed/lillnhis.kir.chunks/lillnhis.kir',
                                           $CFG::CFG->{StartingChunk},
                                           $CFG::CFG->{EndingChunk});
    
    
    #make sure the destination folder exists    
    system('mkdir -p '.$CFG::CFG->{'targetDataDirectory'}.'/History/');
    $writer = ItemWriter->new($CFG::CFG->{'targetDataDirectory'}.'/History/01_history');
}

sub start {
    
    my $startTime = time;
    
    init();
    
    $print->info('Starting history building');
    
    ###Start the business functionality.
    #Init the worker module. This contains all the authorities. This is replicated for each thread. Such is the way Perl's magic works. Sharing authorities effectively is impossible.
    my $reader = HistoryImportChain::Reader->new();

    my $threadRoutine = sub { my $threadId = shift().'';
        if ( $CFG::CFG->{HistoryImportChain}->{BuildHistory} ) {
            
            my ($chunk, $chunkSuffix) = $chunker->fetch($threadId);
			$reader->setThreadId($threadId);
            
            #Thread-safely request a new chunk for the thread to process. Chunk == a unix-split:ted source file
            while ( $chunk ) {
		
				$reader->setNewChunk($chunk);
				$writer->setNewChunk($chunkSuffix);

                $print->info('+Thread '.$threadId.': Processing chunk '.$chunkSuffix);
                

				$print->info('++Thread '.$threadId.': Reading history');
                
                #get a biblio slice. Slice == part of a chunk read to memory and processed to the internal memory model (MARC::Record).
                while ( my $processedChunk = $reader->processChunk() ) {
                
					$writer->writeItems($processedChunk);
		    
					$print->info('Thread '.$threadId.': Freeing written Chunk '.$chunkSuffix.' from memory');
					foreach my $checkout (@$processedChunk) {
						$checkout->DESTROY();
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
    
    $print->info('History processed in ',((time-$startTime)/60),'minutes.');
}

#Make compiler happy
1;