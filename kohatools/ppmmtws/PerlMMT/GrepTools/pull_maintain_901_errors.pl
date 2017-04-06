#!/usr/bin/perl

##TESTING; NOT IN USE
##WORK CANCELED BECAUSE WAS TOO COMPLEX VS SOURCE SIZE
#requires the log file from stdin

use strict;
use warnings;
use utf8;

my $logFilePath = '../log_to_db';
my $licmarca_chunk_filename_without_chunkid = "../../PallasProDumps/target/Biblios/03_biblios.";
my $licmarcaFilePath = '../../PallasProDumps/licmarca.kir';

my $LOGFILE;
my $LICMARCA_CHUNK;
my $LICMARCA;



my $chunk;
my $fetch_these_lines = {};
my $docids = {};

open ($LOGFILE, "<:utf8", $logFilePath);
while (<$LOGFILE>) {
    if ($_ =~ /DatabaseWriter>> \+Thread 0: Processing chunk (\d+)/) {
        find_docids() if defined $LICMARCA_CHUNK && (keys %{$fetch_these_lines});
        close $LICMARCA_CHUNK if defined $LICMARCA_CHUNK;
        open ($LICMARCA_CHUNK, "<:utf8", "$licmarca_chunk_filename_without_chunkid$1") or die $!;
    }
    elsif ($_ =~ /^DBD::Pg::db selectrow_array failed:/) {
        my $errline = $_;
        my $row = readline($LOGFILE);
        
        if ($row =~ /CONTEXT:  PL\/Perl function "maintain_901" at BibliosImportChain\/DatabaseWriter.pm line \d+, <\$MARCDATA> line (\d+)./) {
            $fetch_these_lines->{$1} = $errline;
        }
    }
    
}
close $LOGFILE;

sub find_docids {
    my $rowNumber = 0;
    while (<$LICMARCA_CHUNK>) {
        $rowNumber++;
        if (exists $fetch_these_lines->{$rowNumber}) {
            if ($_ =~ /<controlfield tag="001">(\d+)<\/controlfield>/) {
                $docids->{$1} = 1;
                print $fetch_these_lines->{$rowNumber} . $_ . "\n\n";
            }
        }
    }
    close LICMARCA_CHUNK;
}

flesh_docids();
sub flesh_docids {
    open $LICMARCA, "<", $licmarcaFilePath;
    while (<$LICMARCA>) {
        my $docid;
        if ($_ =~ /^\s+(\d+)\s/) {
            $docid = $1;
        }
        if (defined $docid && exists $docids->{$docid}) {
            #print $_;
        }
    }
    close LICMARCA_CHUNK;
}