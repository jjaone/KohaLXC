## ! IN THIS FILE ! ##
#-We translate our source data to UTF-8 from whichever horrible encoding they stem from.
#-Sort source files according to primary key.
#-Remove empty rows

package PreProcess::PreProcess;

use warnings;
use strict;
#use diagnostics;
use threads;
use threads::shared;
use POSIX;


use CommonRoutines;
use PreProcess::PreProcessConfig;
use PreProcess::SourceSanitizer;
use PreProcess::Utf8Sanitator;
use LiteLogger;


my $threadCount;
my $threads;
my $sourceDataDirectory;
my $targetDataDirectory;
my $chunkSize;

my @sourceFiles :shared; #The filenames that need to be PreProcessed
my %sourceFilesExpectedColumnCounts;
my %sourceFilesColumnsWithLengthIndicators;
my %chunkable;
my $print;


#stores the character encodings used for different source files
my %characterEncodings;

sub run {
    
    my $args = {@_};
    
    my $config = PreProcess::PreProcessConfig::getInstructions();
    my $moduleCFG = $config->{$args->{package}} if defined $args->{package};
    
    my $startTime = time;
    
    #Package variables    
    $threadCount = $CFG::CFG->{threadCount};
    $threads = [];
    #EO Package variable introduction
    
    $print = LiteLogger->new({package => 'PreProcess'});
    $sourceDataDirectory = $CFG::CFG->{'sourceDataDirectory'};
    $targetDataDirectory = $CFG::CFG->{'targetDataDirectory'};
    $chunkSize = $CFG::CFG->{ChunkSize};

    
    $print->info("STARTING PreProcess.pm, feeling good!");
    
    @sourceFiles = @{ $moduleCFG->{sourceFiles} };
    %sourceFilesExpectedColumnCounts = %{ $moduleCFG->{sourceFilesExpectedColumnCounts} };
    %sourceFilesColumnsWithLengthIndicators = %{ $moduleCFG->{sourceFilesColumnsWithLengthIndicators} };
    %chunkable = %{ $moduleCFG->{chunkable} };
    %characterEncodings = %{$CFG::CFG->{'PreProcess'}->{'CharacterEncodings'}};

    #Extract the evergreenDump.tar received from the PallasPro database server export path proxy Xen::/home/ftp/xen_to_oplib.sh @ 10.1.63.15
    $print->info("Extracting evergreenDump.tar");
    #system("tar -C $sourceDataDirectory -xvf $sourceDataDirectory/evergreenDump.tar");

    sub threadRoutine {
        my $threadId = shift;
        while ( my $fileName = getSourceFile() ) {

            $print->info("-Thread $threadId, Starting with $fileName");
	    
			#get the preprocessing folder
				my $folder = "$sourceDataDirectory/preprocessed/";
				if (defined $chunkable{$fileName}) {
					$folder = "$sourceDataDirectory/preprocessed/$fileName.chunks/" ;
					system("mkdir -p $folder");
				}
			
			#decide should we sanitize this file?
			if ($sourceFilesExpectedColumnCounts{$fileName}) {
				$print->info("---Thread $threadId, Sanitizing $fileName");
				PreProcess::SourceSanitizer::sanitizeRows( "$sourceDataDirectory/$fileName",
							  "$folder/$fileName.unsortedunverifiedunencoded",
							   $sourceFilesExpectedColumnCounts{$fileName},
							   $sourceFilesColumnsWithLengthIndicators{$fileName});
			}
			else {
				system("cp $sourceDataDirectory/$fileName $folder/$fileName.unsortedunverifiedunencoded");
			}
			
			#Encode to utf8
			my $sourceEncoding = getSourceFileCharacterEncoding($fileName);
			if ($sourceEncoding eq 'SKIP') { 
				$print->info("--Thread $threadId, Skipping encoding for $fileName");
				system("mv $folder/$fileName.unsortedunverifiedunencoded $folder/$fileName.unsortedunverified");
			}
			else {
				$print->info("--Thread $threadId, Encoding $fileName");
				system("iconv -f $sourceEncoding -t UTF-8 -c $folder/$fileName.unsortedunverifiedunencoded > $folder/$fileName.unsortedunverified"); #do character conversion
				system("rm $folder/$fileName.unsortedunverifiedunencoded");
			}
			
			
			#Verify and sanitize utf8
			if ($sourceEncoding eq 'SKIP') { 
				system("mv $folder/$fileName.unsortedunverified $folder/$fileName.unsorted");
			}
			else {
				$print->info("---Thread $threadId, Verifying utf8 $fileName");
				PreProcess::Utf8Sanitator::sanitate("$folder/$fileName.unsortedunverified",
								"$folder/$fileName.unsorted");
				system("rm $folder/$fileName.unsortedunverified");
			}
			
	
			#Sort the file
			$print->info("----Thread $threadId, Sorting $fileName");
			system("sort -t'\t' -n -k1 -k2 -k3 $folder/$fileName.unsorted > $folder/$fileName");
			system("rm $folder/$fileName.unsorted");
				
			if (defined $chunkable{$fileName}) {
			
				$print->info("------Thread $threadId, Splitting $fileName to thread-digestable chunks");
			
				if ($fileName eq 'licmarca.kir') {
					splitLicmarcaToChunks("$folder/$fileName", $chunkSize)
				}
				else {
					system("split --suffix-length=4 -d -l $chunkSize $folder/$fileName $folder/$fileName");
				}
				
				system("rm $folder/$fileName");
			}
        }
    }
 
    ### Threaded programming starts HERE ###
    #Initialize threads
    if ($threadCount > 0) {
        for my $i (0..$threadCount) {
            $threads->[$i] = threads->create( "threadRoutine", $i );
        }
    } ##EO Threaded programming
    ### Synchronous programming HERE ###
    else {
	threadRoutine($threadCount);
    }## EO Synhronous programming
    
    sub getSourceFile {
        lock @sourceFiles;
        return shift @sourceFiles;
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
    
    print "PreProcessed in ";
    print time - $startTime;
    print " seconds";
}

#PARAM1, $fileName, eg. 'lilcust.kir'
sub getSourceFileCharacterEncoding {
#      'licmarca.kir','licinfoa','licauthp','licauthc','licauths','liqlocde','liccopyi','liccopy'
    if ( my $encoding = $characterEncodings{$_[0]} ) {
	return $encoding;
    }
    else {
	return $characterEncodings{'DEFAULT'};
    }
}



#Licmarca needs special care when splitting it to chunks.
#We need to make sure we don't break any component part groups
sub splitLicmarcaToChunks {
    my $sourceFile = shift;
    my $destinationFile = $sourceFile;
    my $chunkSize = shift;
    
    my $chunkNumber = 0;
    
    open my $IN, "<$sourceFile";
    open my $OUT, ">$destinationFile".sprintf("%04d", $chunkNumber);
    
    #this regexp finds rows which are neither component parts nor multirow records
    #This is required so we don't accidentally splice forementioned record types to seaprate chunks, so we cannot relink/merge them.
    #skip the first column (docid) and make sure that childid == 0 and rowid == 1
    my $regexp = '^\d+\s+0\s+1';
    
    #Tells the loop, that we are iterating a chain of componenent part/multirow records, and when we find the next single/starter record, we can change chunks
    my $insideChainRecord = 0;
    
    #Counts how many records have been written inside the current chunk
    my $counter = 1;
    
    #Open a new chunk for writing
    my $newChunk = sub {
	close $OUT;
	$chunkNumber++;
	open $OUT, ">$destinationFile".sprintf("%04d", $chunkNumber);
	$counter = 1;
	$insideChainRecord = 0;
    };
    
    while (<$IN>) {

	if (isDeleted($_)) { #if the record is deleted,
	    next(); #skip it
        } #allowing deleted records to breach this chunking mechanism, will cause bad things to happen
	
	if ($counter >= $chunkSize) {
	    if (!($_ =~ m/$regexp/)) {
		print $OUT $_;
		$insideChainRecord = 1; #let us know that the current row is a part of a componenent part/multirow record
	    }
	    else {
		if ($insideChainRecord) {	#if we have been iterating a component part/multirow record, $regexp proves that the current row is a starter record
		    
		    &$newChunk();
		    
		    print $OUT $_;
		}
		else {
		    my $newRow = readline($IN);
		    while ( isDeleted($newRow) ) {
			$newRow = readline($IN);
		    }
		    if ($newRow =~ m/$regexp/) { #new row is a single/starter record
			print $OUT $_;
			
			&$newChunk();
			
			print $OUT $newRow;	#new row starts the new chunk
		    }
		    else {	#if new row is a component part/multirow record
			&$newChunk();
			
			print $OUT $_;	#start the new chunk with the current row, which is a starter record
			print $OUT $newRow;
			$counter++;
		    }
		}
	    }
	    $counter++;
	}
	else {
	    print $OUT $_;
	    $counter++;
	}
    }
}

sub isDeleted { #is partially duplicated in BibliosImportChain::FinMARC_Builder::BuildMARC::resolveStatus;
    
    my @row = split("\t",shift);
    #my @bytes = CommonRoutines::breakIntegerToBinaryArray(  $row[5]  );
    
    #if ($bytes[-8] || $bytes[-7]) { #if the record is deleted,
    if ( $row[5] < 0 ) { #if the record is deleted,
	return 1;
    }
    return 0;
}


#Make compiler GAY GAY GAY!
1;