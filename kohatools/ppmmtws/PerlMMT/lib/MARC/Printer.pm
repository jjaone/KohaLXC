package MARC::Printer;

use strict;
use warnings;

use XML::Writer;

use CommonRoutines;

my $writer;
my $MARCXML;
my $SERIALXML;
my $SERIALMOTHERXML;
my $recordCount = 0;

my $targetFile;
my $targetSerialsFile;
my $targetSerialMothersFile;


sub startCollection {
    #Load configuration variables
    my $suffix = shift;
    $targetFile = $CFG::CFG->{'targetDataDirectory'}.'/Biblios/01_biblios.'.$suffix;
    system('mkdir -p '.$CFG::CFG->{'targetDataDirectory'}.'/Biblios/');
    $targetSerialsFile = $CFG::CFG->{'targetDataDirectory'}.'/Serials/01_serials.'.$suffix;
    system('mkdir -p '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/');
    $targetSerialMothersFile = $CFG::CFG->{'targetDataDirectory'}.'/Serials/01_serialmothers.'.$suffix;
    system('mkdir -p '.$CFG::CFG->{'targetDataDirectory'}.'/Serials/');

    #Init file streams
    open $MARCXML, ">:utf8", $targetFile or die $!.": $targetFile"; #stores entries for issues with source data. Missing fields etc.
    select((select($MARCXML), $|=1)[0]); #make filehandle hot!
    open $SERIALXML, ">:utf8", $targetSerialsFile or die $!.": $targetSerialsFile";
    select((select($SERIALXML), $|=1)[0]); #make filehandle hot!
    open $SERIALMOTHERXML, ">:utf8", $targetSerialMothersFile or die $!.": $targetSerialMothersFile";
    select((select($SERIALMOTHERXML), $|=1)[0]); #make filehandle hot!
    #EO file stream init

    print $MARCXML '<?xml version="1.0" encoding="UTF-8"?>'."\n";
    print $MARCXML '<collection xmlns="MarcXChange"><?xml version="1.0" encoding="UTF-8"?>'."\n";

    #MARC::Printer is ready to accept printable records!
}
sub writeRecords {
    my $records = shift;
    my $maxRecordLength = $CFG::CFG->{BibliosImportChain}->{MaxRecordLength};

    foreach (sort {$a <=> $b} keys %{$records}) {

        my $r = $records->{$_};

        #Skip deleted records, like a boss!
        if ($r->isDeleted()) {
            next;
        }


        my $fieldType;

#if ($r->docId == 19391) { #DEBUG
#	my $break;
#}
#if ($r->isASerialMother()) {
#	print "break";
#}

## Unique field 003 contents
# &#168 BTJ00 ENO01 JKL00 JKLML JNS00 JOENS JOKUN KAJ00 KOIVI LINDA LIPER OUL00 TKU00 TRE00

        #Write serials to their own files, other MARC to biblios
        my $OUT;
        my @sb; #Initialize a new StringBuilder(TM) to collect all printable text for one huge IO operation.

        my $f003a = $r->getUnrepeatableSubfield('003','a');
        my $biblioOrigin = $f003a ? $f003a->content() : '';
        if ( ! $r->isASerial() || $biblioOrigin eq 'KOIVI')  {   $OUT = $MARCXML   }
        elsif ( $r->isASerialMother() )  {   $OUT = $SERIALMOTHERXML   } #SerialMother needs to be checked first, as SerialMother is also a serial
        elsif ( $r->isASerial() )  {   $OUT = $SERIALXML   }
        else {   warn("\nMARC::Printer: ".$r->docId()." is not-not a serial or a serial or a serialmother?\n");   }

        push @sb, '<record format="FINMARC" type="Bibliographic">'."\n";
        push @sb, '  <leader>'.$r->leader.'</leader>'."\n";

        ##iterate all the fields
        foreach my $f ( @{$r->getAllFields("sorted")} ) {

            unless ($f->code()) {
                print "Biblio docId '".$r->docId."' has an empty field!";
            }

            if($f->code lt '010') { $fieldType = 'controlfield' }
            else { $fieldType = 'datafield'; }

            push @sb, '  <'.$fieldType.' tag="'.$f->code.'" ind1="'.$f->indicator1.'" ind2="'.$f->indicator2.'">';

            foreach my $sf (  @{ $f->getAllSubfields('sorted') }  ) {

                if($fieldType eq 'controlfield') {
                    push @sb, $sf->content;
                }
                else {
                    if (not($sf->code) || not($sf->content)) {
                        my $dbg = 1;
                    }
                    
                    push @sb, "\n".'    <subfield code="'.$sf->code.'">'.$sf->content.'</subfield>';
                }
            } #EndOf subfields iteration
            if ($fieldType eq 'datafield') {
                push @sb, "\n".'  </'.$fieldType.">\n";
            }
            else {
                push @sb, '</'.$fieldType.">\n";
            }
        } #EndOf fields iteration
        push @sb, '</record>'."\n";

        my $marcString = join('',@sb);
        if (length($marcString) <= $maxRecordLength) {
            print $OUT $marcString;
        }
        else {
            warn("\nMARC::Printer: Record docId '".$r->docId()."' is massively overgrown with '".length($marcString)."' characters and thus is skipped.\nMaximum is $maxRecordLength characters. Otherwise this Record might cause troubles when indexing.\n");
        }
    }
}
sub endCollection {

    print $MARCXML '</collection>'."\n";

    close $MARCXML;
    close $SERIALXML;

    return ($targetFile, $targetSerialsFile, $targetSerialMothersFile);
}

#make compiler happy!
1;