package BibliosImportChain::Controller;

use warnings;
use strict;
#use diagnostics;
use utf8;
use threads;
use threads::shared;
#use Devel::SizeMe qw(total_size perl_size);
#use Devel::Cycle;
#use Devel::Leak;
#use Test::LeakTrace;
use IO::File;
use LiteLogger;


use PreProcess::PreProcess;
use BibliosImportChain::FinMARC_Builder::PP_To_MARC;
use MARC::Printer;
use Repository::MarcRepository;
use ChunkDealer;
use BibliosImportChain::MarcRepair;

my $sourceDataDirectory;

my $USEMARCON_LOG; #will hold a output stream, perl automatically shares this between all processes.
my $LICAUTHMARC;
my $print;

my $threads = [];

sub start {
    
    my $moduleStartTime = time;
    
    $print = LiteLogger->new({package => 'BibliosImportChain::Controller'});
    open $USEMARCON_LOG, ">:utf8", $CFG::CFG->{BibliosImportChain}->{UsemarconLog} or die "Can't open ".$CFG::CFG->{BibliosImportChain}->{UsemarconLog}.": $!";
    
    $print->info('Starting biblios building');
    
    #Load configuration variables
    $sourceDataDirectory = $CFG::CFG->{'sourceDataDirectory'};
    
    ##Run the PreProcessor if requested, or if preprocessed files are not found.
    my $firstLicmarcaChunk = $sourceDataDirectory.'/preprocessed/licmarca.kir.chunks/licmarca.kir0000';
    if (! (-e $firstLicmarcaChunk) || $CFG::CFG->{BibliosImportChain}->{PreProcess}) {
        print "\nNOTE: Preprocessing source files because no preprocessed source files found in '$firstLicmarcaChunk'.\n" if ! (-e $firstLicmarcaChunk);
        PreProcess::PreProcess::run(package => 'BibliosImportChain');
    }
    
    #Init the ChunkDealer to provide licmarca-chunks for threads to process
    my $chunker :shared = ChunkDealer->new($sourceDataDirectory.'/preprocessed/licmarca.kir.chunks/licmarca.kir',
                                           $CFG::CFG->{StartingChunk},
                                           $CFG::CFG->{EndingChunk});
    
 
    #Make sure that we add the component parts after the last marc record in licmarca.kir
    my $highestFreeDocId = CommonRoutines::getHighestFreeDocid( $chunker->getLastChunk() );
    if ($highestFreeDocId >= $CFG::CFG->{BibliosImportChain}->{NextFreeDocId}) {
        $print->error('Configuration variable   NextFreeDocId   is less than the highest docId used by licmarca.kir. Using corrected configuration value '.$highestFreeDocId);
        $CFG::CFG->{BibliosImportChain}->{NextFreeDocId} = $highestFreeDocId;
    }

    #Prepare the licauthmarc.repo file. licauthmarc.repo is used by the ItemsInjector to get certain record-specific entries
    if (   $CFG::CFG->{StartingChunk} == 0 && ( ($CFG::CFG->{EndingChunk} < 0) || ($CFG::CFG->{EndingChunk} > 49) ) ) { #TODO/FIX:Kohalappi: do the overwrite also when more than 50 marc records chunks are converted. This is to make it possible to generate licauthmarc.repo for some partial conversions if it does not exist for BibItemsImportChain runs that need it anyaways
    #if (   $CFG::CFG->{StartingChunk} == 0 && $CFG::CFG->{EndingChunk} < 0   ) { #only do the overwrite when all marc records are converted. This is to prevent licauthmarc.repo from getting formatted on every BibItemsImportChain run
		open ($LICAUTHMARC, '>:utf8', $sourceDataDirectory.'/preprocessed/licauthmarc.repo') or die "Can't open ".$sourceDataDirectory.'/preprocessed/licauthmarc.repo'.": $!";
		select((select($LICAUTHMARC), $|=1)[0]); #make filehandle hot!
    }

    ###Start the business functionality.
    #Init the worker module. This contains all the authorities. This is replicated for each thread. Such is the way Perl's magic works. Sharing authorities effectively is impossible.
    my $pp_To_MARC_Converter = BibliosImportChain::FinMARC_Builder::PP_To_MARC->new();

    my $perlSize = [];
    my $threadRoutine = sub { my $threadId = shift().'';
        if ( $CFG::CFG->{BibliosImportChain}->{BuildMARC} ) {
            
            $pp_To_MARC_Converter->setThreadId($threadId);
            my ($chunk, $chunkSuffix) = $chunker->fetch($threadId);
			
			BibliosImportChain::MarcRepair::init($threadId);
            
            #Thread-safely request a new chunk for the thread to process. Chunk == a unix-split:ted source file
            while ( $chunk ) {
		
		#DEBUG
		#my $count = Devel::Leak::NoteSV('BibliosImportChain::Controller');


                $print->info('+Thread '.$threadId.': Processing chunk '.$chunkSuffix);
                
				#{   Converting PP to FinMARCXML   #
				$print->info('++Thread '.$threadId.': Converting PP to FinMARCXML');
		
                MARC::Printer::startCollection( $chunkSuffix );  #last two characters are the chunk number
                $pp_To_MARC_Converter->setNewChunk( $chunk );
                
                #get a biblio slice. Slice == part of a chunk read to memory and processed to the internal memory model (MARC::Record).
                while ( my $processedChunk = $pp_To_MARC_Converter->processChunk() ) {

					my $startTime = time();
					BibliosImportChain::MarcRepair::run($processedChunk, $chunkSuffix, $pp_To_MARC_Converter);
					$print->info('Thread '.$threadId.': Chunk '.$chunkSuffix.' MarcRepaired in '.(time() - $startTime). 's');
		
					$startTime = time();
					MARC::Printer::writeRecords($processedChunk);
					$print->info('Thread '.$threadId.': Chunk '.$chunkSuffix.' wrote as 01_biblios. in '.(time() - $startTime). 's');
					
					if (defined $LICAUTHMARC) {
						#Write this chunk as the licauthmarc.repo repository for ItemsInjector to use.
						$startTime = time();
						Repository::MarcRepository::createFileFromMARC_Records($processedChunk, $LICAUTHMARC);
						$print->info('Thread '.$threadId.': Chunk '.$chunkSuffix.' wrote as MarcRepository in '.(time() - $startTime). 's');
					}
										
					$startTime = time();
					foreach my $key (keys %$processedChunk) {
						$processedChunk->{$key}->DESTROY();
					}
					$print->info('Thread '.$threadId.': Chunk '.$chunkSuffix.' freed from memory in '.(time() - $startTime). 's');
		#		    Devel::Cycle::find_cycle($biblioSlice);
                }
                
                my @finmarcXmlFileChunkPaths = MARC::Printer::endCollection();

                #}   Converted as FinMARCXML   #
		
				if ($CFG::CFG->{BibliosImportChain}->{RunUSEMARCON} ) {
					#{   Converting FinMARCXML to MARC21XML  #
					$print->info('++Thread '.$threadId.': Converting FinMARCXML to MARC21XML');
					
					my $usemarconDir = 'BibliosImportChain/Usemarcon';
					## [TODO]:KohaLappi; Do we really need to make sure usemarcon is executable!
					#system('sudo chmod +x '.$usemarconDir.'/usemarcon');
					
					foreach my $sourcePath (@finmarcXmlFileChunkPaths) {
						
						my $usemarconOutput = $sourcePath;
						my $flattenedXml = $sourcePath;
						$usemarconOutput =~ s/01/02/; #renumbering destination chunk filenames.
						$flattenedXml =~ s/01/03/;
						my $usemarconCommand = "$usemarconDir/usemarcon $usemarconDir/fi2ma/fi2ma.ini $sourcePath $usemarconOutput | ";
						
						open(USEMARCON_OUTPUT, $usemarconCommand) or die "Can't open pipe for $usemarconCommand: $!";
						while (my $logMessage = <USEMARCON_OUTPUT>) { #us file streams are shared, we get all threads to write to this same logfile logging from all chunks
							print $USEMARCON_LOG $logMessage;
						}
						close USEMARCON_OUTPUT;
						
						#Verify xml integrity and flatten it
						open(XML_FLATTEN_SOURCE, "<:utf8", $usemarconOutput)  or die "Can't open $usemarconOutput: $!";
						open(XML_FLATTEN_TARGET, ">:utf8", $flattenedXml)  or die "Can't open $flattenedXml: $!";
						my $firstRecordFound = 0; #We need to separate xml-headers and MARC-standard <collection>-tags from the <record>-tags. This boolean is needed to separate the first <record> from the <collection>-tag
						while (my $flattenMe = <XML_FLATTEN_SOURCE>) {
							chomp $flattenMe;
							if (! $firstRecordFound && $flattenMe =~ m/<record/) {
								$flattenMe =~ s/<record/\n<record/;
								$firstRecordFound = 1;
							}
							$flattenMe =~ s/<\/record>/<\/record>\n/; #separate the <record>s from each others and the from the last <collection>
							print XML_FLATTEN_TARGET $flattenMe;
						}
						close(XML_FLATTEN_SOURCE);
						close(XML_FLATTEN_TARGET);
					}
					#}   Converted to MARC21XML  #
				}

                ($chunk, $chunkSuffix) = $chunker->fetch($threadId);
				sleep(1);
            }
            $print->info("\n".'++++ Thread '.$threadId.': Exiting happily! ++++'."\n");
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
    
    
    #$LICAUTHMARC->close();
    close $LICAUTHMARC if defined $LICAUTHMARC;
    close $USEMARCON_LOG;
	
	#Preparing Serials for Groovy insertion.
	system('cat '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/02_serialmothers.*'.' > '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/serialmothers.marc');
	#system('rm '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/01_serialmothers.*');
	#system('rm '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/02_serialmothers.*');
	#system('rm '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/03_serialmothers.*');
	system('cat '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/02_serials.*'.' > '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/serials.marc');
	#system('rm '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/01_serials.*');
	#system('rm '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/02_serials.*');
	#system('rm '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/03_serials.*');
	
    $print->info('Biblios processed in ',((time-$moduleStartTime)/60),'minutes.');
}

#Make compiler happy
1;
