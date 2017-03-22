## ! IN THIS FILE ! ##
# Stores all component part records and does the linking.
# Stores all multirow records and merges them
package BibliosImportChain::FinMARC_Builder::SharedDocidRecordsHandler;

use warnings;
use strict;
#use Devel::SizeMe qw(total_size perl_size);
my $totalSize = [];
use POSIX;
use LiteLogger;

my $sharedRecords; #hash->{docId}->[childId]->[rowId-1] of stored component part records.
                   #rowId-1 because rowId's start from 1 and array index from 0
my $t; #pointer to the controlling BibliosImportChain::FinMARC_Builder::PP_To_MARC -object;

my $log;

sub init { 
    $sharedRecords = {};
    $log = LiteLogger->new({package => 'BibliosImportChain::FinMARC_Builder'});
    $t = shift;
}

#Shared records have three parameters which control their core essence.
#docId is the record id that signals that these records are definetely connected
#childId which indicates a component part relation,
#and rowId which indicates that the marc record was too large to fit in one 1000-characters long column.
#Every childId can have multiple rows or rowid's (pretty unlikely though).
#We must organize shared records according to the docId, childId and then sort according to the rowId so we can merge these split records, before making component part linkings.
sub storeSharedRecord {
    #lock $componentParts;
    my $record = shift;
    my $docId = $record->docId();
    my $childId = $record->childId();
    my $rowId = $record->rowId();
    
    #store the $record to
    #$sharedRecords->{$docId}->[$childId]->[$rowId] = $record;
    
    #find out if the docId layer has been established for this shared record or establish it
    if ( exists $sharedRecords->{$docId} && ref $sharedRecords->{$docId} eq 'ARRAY' ) {
        #do nothing as the docId array has already been initialized
    }
    else {
        $sharedRecords->{$docId} = [];
    }
    my $docIdLevel = $sharedRecords->{$docId};
    
    #find out if the childId layer has been established for this shared record or establish it
    if ( exists $docIdLevel->[$childId] && ref $docIdLevel->[$childId] eq 'ARRAY' ) {
        #do nothing as the childId array has already been initialized
    }
    else {
        $docIdLevel->[$childId] = [];
    }
    my $childIdLevel = $docIdLevel->[$childId];
    
    #find out if the rowId layer has been established for this shared record or establish it
    if ( exists $childIdLevel->[$rowId] && ref $childIdLevel->[$rowId] eq 'ARRAY' ) {
        $childIdLevel->[$rowId] = $record;
    }
    else {
        $childIdLevel->[$rowId] = $record;
    }
}

=linkSharedRecords
Links using 773w -> 001 two biblios that are component parts.
Parent is identified by the rowid value of 0, where each subsequent child has rowid > 0
All component parts are first stored into %unlinkedChildComponentParts->{docid}->[].
We don't know in which order the childs are introduced, they might come before the parent, so we must check that the (rowid == 0) master biblio gets to save its docid, others get a new docid after all items are added.
#new docid is given after $nextFreeDocid
$_[0]: the existing biblio id 
$_[1]: the new biblio with a same id
=cut
sub linkSharedRecords {
    
    
    #Iterate through the stored docId-sharing record -arrays
    foreach my $docId ( keys %$sharedRecords ) {
    
        #pull the record stored to $t = BibliosImportChain::FinMARC_Builder::PP_To_MARC.
        #so we can include all the records sharing the same docid to this linking process.
        my $childIdsList = $sharedRecords->{$docId};
        
        storeSharedRecord(  $t->findRecord($docId)  );
        $t->releaseRecord($docId);
        
        ##Merge multirow records
        my $mergeMultirowRecords = sub {
            
            for (my $j=0 ; $j<@$childIdsList ; $j++) {
            my $rowIdsArray = $childIdsList->[$j];
            
            #Some records are deleted, and have component parts lying around. Catch them and remove!
            #We exclude the whole set if the component parent is deleted (missing here, because it is deleted in BuildMARC->buildCoreData())
            if (! (ref $rowIdsArray eq 'ARRAY') ) {
                if ($j == 0) { #if we are currently iterating the component parent, remove all records sharing the same docid, as they are deleted/obsolete
                    print "Docid: $docId: Multirow PARENT IS MISSING";
                    return 'PARENT IS MISSING';
                }
                else { #the component parent exists, so we have encountered a removed component part, skip this Recordless childId
                    print "\n\n\n\nTHIS SHOULD NEVER HAPPEN!\nIN SHARED DOCID RECORDS HANDLER\nDocid: $docId\n\n\n";
                    next(); #this should never happen
                }
            }
            
            for (my $i=2 ; $i<@$rowIdsArray ; $i++) {
                mergeRecords(  $rowIdsArray->[1] , $rowIdsArray->[$i]  );
                $rowIdsArray->[$i]->DESTROY();
            }
            $childIdsList->[$j] = $rowIdsArray->[1]; #Replace the $rowIdsArray with the merged Record
            }
        };
        
        #If the component parent Record is missing and we find stranded component children, destroy them.
        if (&$mergeMultirowRecords() eq 'PARENT IS MISSING') {
            destroyChildIdsListContents($childIdsList);
            next();
        }
        
        my $highestReservedDocId = $t->reserveFreeDocIds(-1 + @$childIdsList); #we can exclude the parent as it already stores one docId
        my $nextFreeDocid = $highestReservedDocId - (-1 + @$childIdsList); #This is the next free docid we can give to consecutive component parts
        
        ##find the parent record, identified with childId == 0 && rowId == 1. Parent gets to store it's docId so childs can refer to it.
        #Parent also doesn't need no 773-additions
        my $parent = $childIdsList->[0];
        
        ##If the parent is marked for deletion, this is the time to delete it with all of it's protegé.
        ##Only the parent is marked DELETED in PP, so the children will be stranded if parent is deleted,
        ## without first collecting them.
        if ($parent->isDeleted()) {
            $t->releaseRecord($docId);
            destroyChildIdsListContents($childIdsList);
            $parent->DESTROY();
            next();
        }
        
        $t->storeRecord($parent); #replace the record inside $t->{records} with the definite parent component part.
        
        #parse the MARC-string to a MARC::Record object
        #Component parts require MARC editing, but multirow records cannot be merged after MARC is parsed.
        #This creates a pretty nasty situation where the MARC::Record needs to be populated in 3 separate places.
        BibliosImportChain::FinMARC_Builder::BuildMARC::extractMARCFields($parent);
        BibliosImportChain::FinMARC_Builder::BuildMARC::replaceAuthorityCodesWithAuthorityValues($parent, $t);
        delete $parent->{marc};
        
        ##Populate the 773-fields for child records
        #We won't iterate the parent Record residing in $childIdsList->[0], so we start iterating from index 1
        for (my $j=1 ; $j<@$childIdsList ; $j++) {
            my $r = $childIdsList->[$j];

            unless ($r) {
                $log->warning("Component part childId '$j' is missing for parent docid '$docId'!");
                next();
            }
            $r->docId($nextFreeDocid++);
            
            #parse the MARC-string to a MARC::Record object AGAIN!
            BibliosImportChain::FinMARC_Builder::BuildMARC::extractMARCFields($r);
            BibliosImportChain::FinMARC_Builder::BuildMARC::replaceAuthorityCodesWithAuthorityValues($r, $t);
            delete $r->{marc};
    
            #Creating the bare docId-link
            #Skipping if $773 already defined
            my $f773 = $r->getUnrepeatableField('773');

            if ( ! $f773 ) {
                $f773 = MARC::Field->new("773");
                $r->addField($f773);
            }
            
            ##  Making sure field 773 has properly filled subfields ##
            #Enforce 773w linkage, replace values like "pf00073376" with the parents docId
            my $f773w = $f773->getUnrepeatableSubfield('w');
            if ($CFG::CFG->{organization} eq 'pielinen') { #In Pielinen, the 773w has been obfuscated and needs to be rebuilt based on the linking PP uses.
                my $control001 = $parent->getUnrepeatableSubfield('001','a');
                if (! defined $control001) {
                    $log->warning("Component part parent docid $docId has no field 001!");
                }
                else {
                    unless ($f773w) {
                        $f773w = MARC::Subfield->new( "w",$control001->content() );
                        $f773->addSubfield( $f773w );
                    }
                    else {
                        $f773w->content( $control001->content() );
                    }
                }
            }
            elsif ($CFG::CFG->{organization} eq 'jokunen') { #In Jokunen, if the 773w-linking is missing we must rebuild it, but otherwise they are always correct.
                if (! $f773w)  {
                    my $control001 = $parent->getUnrepeatableSubfield('001','a');
                    if (! defined $control001) {
                        $log->warning("Component part parent docid $docId has no field 001!");
                    }
                    else {
                        $f773w = MARC::Subfield->new( "w",$control001->content() );
                        $f773->addSubfield( $f773w );
                    }
                }
            }
            ##USEMARCON scres the field 773$w with some strange non-word characters [. -]. Those are cleaned in bulkMarcPostImport.pl because the
            ##773$w needs to be realigned to the translated parent biblionumber, because the biblionumbers are not preserved, due to existing Biblios
            ##conflicting with the new biblionumbers.

            #Enforce 773t linkage
            my $f773t = $f773->getUnrepeatableSubfield('t');
            if (! $f773t)  {
                my $titleFromSF = $parent->getUnrepeatableSubfield('245','a');
                $titleFromSF = $parent->getUnrepeatableSubfield('240','a') if (! $titleFromSF);
                if (! defined $titleFromSF) {
                    $log->warning("Component part parent docid $docId has no field 245a or 240a!");
                }
                else {
                    my $f773t = MARC::Subfield->new( "t",$titleFromSF->content() );
                    $f773->addSubfield( $f773t );
                }
            }
            #Enforce 773a linkage
            my $f773a = $f773->getUnrepeatableSubfield('a');
            my $f245 = $parent->getUnrepeatableField('245'); #Parent might not have that field!
            if (not($f245)) {
                $log->warning("Component part parent docid $docId has no field 245!");
            }
            elsif ((not($f773a))  &&  $f245->indicator1() != 1) {
                my $authorFromSF = $parent->getUnrepeatableSubfield('100','a');
                $authorFromSF = $parent->getUnrepeatableSubfield('110','a') if (! $authorFromSF);
                $authorFromSF = $parent->getUnrepeatableSubfield('111','a') if (! $authorFromSF);
                if (! defined $authorFromSF) {
                    $log->warning("Component part parent docid $docId has no field 100a or 110a or 111a!");
                }
                else {
                    my $f773a = MARC::Subfield->new( "a",$authorFromSF->content() );
                    $f773->addSubfield( $f773a );
                }
            }
            
            #Mark these childs as such, so we can skip them in the MarcRepository building. Component part children have no attached items, so they need not be included in the MarcRepository.
            $r->isComponentPart(1);
            
            $t->storeRecord($r);
        }
    }
    #empty component parts
    $sharedRecords = {};
}

# %unlinkedChildComponentParts contains an array of all component parts for the marc-entity with the docid-as-hash-hey
# We iterate those component part -arrays and link them to the given marc-entity ($docid) using MARC21 standard of 77x field linking.
#check prepareComponentPart() for more documentation.
=MARC21 standard subfields for field 773

$a - Main entry heading (NR)				$b - Edition (NR)				$d - Place, publisher, and date of publication (NR)
$g - Related parts (R)					$h - Physical description (NR)			$i - Relationship information (R)
$k - Series data for related item (R)			$m - Material-specific details (NR)		$n - Note (R)
$o - Other item identifier (R)				$p - Abbreviated title (NR)			$q - Enumeration and first page (NR)
$r - Report number (R)					$s - Uniform title (NR)				$t - Title (NR)
$u - Standard Technical Report Number (NR)		$w - Record control number (R)			$x - International Standard Serial Number (NR)
$y - CODEN designation (NR)				$z - International Standard Book Number (R)	$3 - Materials specified (NR)
$4 - Relationship code (R)				$6 - Linkage (NR)				$7 - Control subfield (NR)
    /0 - Type of main entry heading			$8 - Field link and sequence number (R)
    /1 - Form of name
    /2 - Type of record
    /3 - Bibliographic level
=cut

#Merges the unprocessed marc-record of param2 to param1.
#param1 the Marc::Record object to append raw marc records to.
#param2 the Marc::Record object from which to take the raw marc record.
#Merge to $_[0]->{marc} the $_[1]->{marc}
sub mergeRecords {

    #The multirow Record supplement Record continues exactly from where the previous entry left off.
    $_[0]->{marc} .= $_[1]->{marc};
}

sub destroyChildIdsListContents {
    my $childIdsList = shift;
    for(my $i=0 ; $i<scalar(@$childIdsList) ; $i++) {
        my $record = $childIdsList->[$i];

        if (ref $record eq 'ARRAY') { #The rows havent been merged yet, so remove the children by the row
            foreach my $rowRecord (@$record) {
                $rowRecord->DESTROY() if (ref($rowRecord) eq 'MARC::Record');
            }
        }
        elsif (ref $record eq 'MARC::Record') {
            $record->DESTROY();
        }
        else {
            #Strangeness
        }
    }
}

1;
