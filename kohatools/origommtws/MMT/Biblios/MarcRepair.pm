package MMT::Biblios::MarcRepair;

use Modern::Perl;

use MMT::MARC::Field;
use MMT::MARC::Subfield;

my $statistics = {};
$statistics->{cleanEmptyField} = 0;
$statistics->{remove856azDuplicates} = 0;
$statistics->{repairPublicationYearFrom260c} = 0;
$statistics->{repairPublicationYearFrom008} = 0;
$statistics->{convertAanikirjaItemtype} = 0;
$statistics->{convertYleItemtype} = 0;
$statistics->{removeTitlelessRecords} = 0;
$statistics->{mergeSeparate260} = 0;
$statistics->{move362aAfter245a} = 0;
$statistics->{removeExtraFields} = 0;
$statistics->{repairMissing084fromItems} = 0;
$statistics->{callNumberRepaired} = 0;
$statistics->{callNumberSalvagedFrom090} = 0;
$statistics->{enableComponentPartNoteController773i1} = 0;

sub run {
    my ($bibliosMigrator, $r) = @_;

    if ($r->isDeleted()) {
        next;
    }

    eval {
    removeTitlelessRecords($r);
    cleanEmptyFields($r);
    remove856azDuplicates($r);
    repairPublicationYear($r);
    mergeSeparate260($r);
    move362aAfter245a($r);
    dropObsoleteFields($r);
    repairMissing084fromItems($bibliosMigrator, $r);
    sanitizeCallNumber($r);
    enableComponentPartNoteController773i1($r);
    };
    if ($@) {
        if ($@ =~ /FAIL/) {
            return undef;
        }
        else {
            die $@;
        }
    }
    return 1;
}

sub cleanEmptyFields {
    my ($r) = @_;

    if (my $fia = $r->fields()) {
        foreach my $fi (@$fia) {
            if ( (my $sfa = $fi->getAllSubfields()) ) {
                unless (  scalar(@$sfa) > 0 ) {
                    $r->deleteField( $fi );
                    $statistics->{cleanEmptyField}++;
                    next;
                }
            }
        }
    }
}

sub mergeSeparate260 {
    my $record = shift;

    if (my $fia = $record->fields('260') ) {
        my $first260 = $fia->[0]; #Store the first field 260 so we can move other's values there.

        for (my $i=1 ; $i<scalar(@$fia) ; $i++) { #Starting from 1, since index 0 is the $first260

            my $f260 = $fia->[$i];
            $first260->mergeField( $f260 );
            $record->deleteField($f260);
            $statistics->{mergeSeparate260}++;
            $i--; #Compensate for the deleted Item
        }
    }
}

sub removeTitlelessRecords {
    my $r = shift;

    foreach (210,222,240,242,245,246) {
        if (my $fia = $r->fields($_) ) {
            return 1; #Looking for records with none of these fields, eg titleless records. Happy to have found a title!
        }
    }
    #No title found so DESTROYING this bastard!
    print("Record '".$r->docId()."' has no title, so removing it.\n");

    $statistics->{removeTitlelessRecords}++;
    die 'FAIL';
}

=head
856-kentän osakenttien a ja z toistumat pois
Priorisoidaan BTJ:ltä tulleita linkkejä.
=cut
sub remove856azDuplicates {
    my ($r) = @_;

    if (my $f856a = $r->fields('856')) {
        my $imageField;
        my $btjImage = 0;
        my $textField;
        my $btjText = 0;
        foreach my $f856 (@$f856a) {
            if (my $sfq = $f856->getUnrepeatableSubfield('q')) {
                if ($sfq->content eq 'IMAGE') {
                    next if $btjImage;
                    $imageField = $f856;
                    my $sfu = $f856->getUnrepeatableSubfield('u');
                    if ($sfu && $sfu->content() =~ m!http://www.btj.com!i) {
                        $btjImage = 1;
                    }
                }
                if ($sfq->content eq 'TEXT') {
                    next if $btjText;
                    $textField = $f856;
                    my $sfu = $f856->getUnrepeatableSubfield('u');
                    if ($sfu && $sfu->content() =~ m!http://www.btj.com!i) {
                        $btjText = 1;
                    }
                }
            }
        }
        for (my $i=0 ; $i<scalar(@$f856a) ; $i++) {
            my $f856 = $f856a->[$i];
            unless (($textField && "$f856" eq "$textField") || ($imageField && "$f856" eq "$imageField")) { #Compare if the object references are the same
                $r->deleteField($f856);
                $i--;
                $statistics->{remove856azDuplicates}++;
            }
        }
    }
}

sub repairPublicationYear {
    my $r = shift;

    sub repair008 {
        my $year = shift;
        my $sf008 = shift;
        my $r = shift;

#        if ($r->materialType() eq 'va') { #verkkoaineisto has no publication dates so using 1000
#            $year = '1000';
#            #$log->warning('Record docid '.$r->docId().' is verkkoainesto (va) and has no publication date. Using 1000.');
#        }

        if ($sf008->content() =~ /^(.{7}).{4}(.+)$/) {
            $sf008->content( $1.$year.$2 );
            $statistics->{repairPublicationYearFrom260c}++;
        }
        else {
            print('repairPublicationYearFrom260c(): Record docid '.$r->docId().' has malformed field 008!');
        }
    }
    sub repair260cFrom008 {
        my $r = shift;
        my $year = shift;

        $r->addUnrepeatableSubfield('260','c', $year);
        $statistics->{repairPublicationYearFrom008}++;
    }

    if (my $sf008 = $r->getUnrepeatableSubfield('008','a') ) {

        if ($sf008->content() =~ /^.{7}(\d{4})/) {
            unless ($r->getUnrepeatableSubfield('260','c')) {
                repair260cFrom008($r, $1);
            }
        }
        else {
            if (my $sf260c = $r->getUnrepeatableSubfield('260','c') ) {
                if ($sf260c->content() =~ /(\d{4})/) {
                    repair008($1, $sf008, $r);
                }
                #Trying to get somekind of a year out of this, usually 260c seems to be like [198-?] or [19-?] etc.
                elsif ($sf260c->content() =~ /(\d{2,4})/) {
                    my $year = $1;

                    while (length $year < 4) { #this created a length 4 string, as full length is reached on last loop iteration
                        $year .= '0';
                    }
                    print('Record docid '.$r->docId().'\'s publication date couldn\'t be completely pulled from 260c, but repairing the year from '.$sf260c->content().' => '.$year."\n");
                    repair008($year, $sf008, $r);
                }
                else {
                    print('Docid '.$r->docId().'\'s 260c couldnt be parsed. No year found from 260c => '.$sf260c->content().'. Using 1899.'."\n");
                    repair008('1899', $sf008, $r);
                }
            }
            else {
                ##Component parts can check their parent for publication date
                #Use postprocessor to fix child record link and publication date fields.
            }
        }
    }
    else {
        print 'Record docid '.$r->docId().' has no field 008!';
    }
}

=head convertAanikirjaItemtype
Called from MMT::MARC::Record::materialType();
=cut
sub convertAanikirjaItemtype {
    my ($r, $materialType) = @_;

    if ($materialType eq 'Aanikirja') {
        my $sf007 = $r->getUnrepeatableSubfield('007','a');
        unless ($sf007) {
            print("Record '".$r->docId()."' has no field 007!\n");
            return '';
        }
        $statistics->{convertAanikirjaItemtype}++;

        my $specificMaterialDesignation = substr($sf007->content(),1,1);
        if ($specificMaterialDesignation eq 'u' || $specificMaterialDesignation eq 'd') {
            return 'CD';
        }
        elsif ($specificMaterialDesignation eq 's') {
            return 'KA';
        }
        else {
            print("Record '".$r->docId()."' has unknown field 007/01 specific material designation!\n");
            return "";
        }
    }

    return $materialType;
}

=head convertYleItemTypes
    Yle-aineistolajit
    Aineistolaji = Yle-video => VHS + items.statistics1 = ‘yle’
    itemtype = Yle-äänite & 007/01 = s => c-kasetti, muutoin CD-levy + items.statistics1 = ‘yle’
    Aineistolaji = Yle-dvd => DVD + items.statistics1 = ‘yle’
=cut
sub convertYleItemTypes {
    my ($r, $materialType) = @_;

    if ($materialType eq 'Yle: video') {
        $statistics->{convertYleItemtype}++;
        $r->{overrides}->{items}->{coded_location_qualifier} = 'yle'; #This is passed to the MarcRepository
        return 'VI';
    }
    elsif ($materialType eq 'Yle: aanitteet') {
        my $sf007 = $r->getUnrepeatableSubfield('007','a');
        unless ($sf007) {
            print("Record '".$r->docId()."' has no field 007!\n");
            return '';
        }
        $statistics->{convertYleItemtype}++;
        $r->{overrides}->{items}->{coded_location_qualifier} = 'yle'; #This is passed to the MarcRepository

        my $specificMaterialDesignation = substr($sf007->content(),1,1);
        if ($specificMaterialDesignation eq 's') {
            return 'KA';
        }
        else {
            return 'CD';
        }
    }
    if ($materialType eq 'Yle: dvd') {
        $statistics->{convertYleItemtype}++;
        $r->{overrides}->{items}->{coded_location_qualifier} = 'yle'; #This is passed to the MarcRepository
        return 'DV';
    }

    return $materialType;
}

sub move362aAfter245a {
    my ($r) = @_;

    if (my $sf362a = $r->getUnrepeatableSubfield('362', 'a')) {
        if (my $sf245a = $r->getUnrepeatableSubfield('245', 'a')) {
            my @enumerations = split('\s?:\s?',$sf362a->content());
            $sf245a->content( $sf245a->content . ' ' . join(' : ', @enumerations) );
            $statistics->{move362aAfter245a}++;
        }

        my $f362a = $r->fields('362');
        if ($f362a) {
            for (my $i=0 ; $i<scalar(@$f362a) ; $i++) {
                my $f362 = $f362a->[$i];
                $r->deleteField($f362);
                $i--;
            }
        }
    }
}
sub dropObsoleteFields {
    my ($r) = @_;
    foreach (['080']) {
        if ($r->fields($_)) {
            $r->deleteFields($_);
            $statistics->{removeExtraFields}++;
        }
    }
}
sub repairMissing084fromItems {
    my ($bibliosMigrator, $r) = @_;
    my $nideRow = $bibliosMigrator->{repositories}->{Nide}->fetch($r->docId);
    if ($nideRow) {
        my $callNumber = $nideRow->[0];
        unless ($r->fields('084')) {
            $r->addUnrepeatableSubfield('084', 'a', $callNumber);
            $statistics->{repairMissing084fromItems}++;
        }
    }
    else {
        #print "Record '".$record->docId()." has no Items.'\n";
    }
}
=head sanitizeCallNumber
First iterate all 084s and repair or drop invalid call numbers.
If no valid call number is found, try to find one from 090
Then drop all 090
=cut
sub sanitizeCallNumber {
    my ($r) = @_;

    sub repairCallNumber {
        my ($callNumber) = @_;
        $callNumber = '' if (! (defined $callNumber)); #prevent undef errors.

        if ( ( length $callNumber < 3 && $callNumber !~ /^\d\d?$/ ) ||
             ( length $callNumber > 2 && $callNumber !~ /^\d\d?\.\d*\D*$/) ) {
            $callNumber =~ s/[ '\*#\[\]]//g; #remove nasty characters, as somehow they intrude here as well
            $callNumber =~ s/,/./g; #replace , with .
            $callNumber =~ s/\.\./\./; #replace .. with .
            if (length $callNumber > 2) {
                if ($callNumber =~ /^(\d\d?).?(\d*\D*)$/) { #create a dot for call numbers missing one
                    $callNumber = $1.'.'.$2;
                }
            }

            if ( ( length $callNumber < 3 && $callNumber !~ /^\d\d?$/ ) ||  #maybe sanitating resolves this error?
               ( length $callNumber > 2 && $callNumber !~ /^\d\d?\.\d*\D*$/) ) {

                if ($callNumber =~ /^(\s|\D)+$/ ||  #If content is only text
                    $callNumber =~ /^........../) { #or bad and too long
                    return ('DEL', $callNumber);
                }
                return ('WARN', $callNumber);
            }
            else {
                return ('FIX', $callNumber);
            }
        }
        return ('OK', $callNumber);
    }

    my $correctCallNumberFound;
    if (my $f084a = $r->fields('084')) {
        foreach my $f084 (@$f084a) {
            if (my $sf084aa = $f084->subfields('a')) {
                for (my $i=0 ; $i<scalar(@$sf084aa) ; $i++) {
                    my $sf084a = $sf084aa->[$i];

                    my ($resolution, $callNumber) = repairCallNumber( $sf084a->content() );
                    if ($resolution eq 'OK') {
                        $correctCallNumberFound = $callNumber;
                    }
                    elsif ($resolution eq 'DEL') {
                        $f084->deleteSubfield($sf084a);
                        $i--;
                        #print("Record '".$r->docId()."' using Call number '$callNumber', bad Call number dropped\n");
                    }
                    elsif ($resolution eq 'WARN') {
                        $sf084a->content( $callNumber );
                        print("Record '".$r->docId()."' using Call number '".$sf084a->content()."', bad Call number preserved\n");
                    }
                    elsif ($resolution eq 'FIX') {
                        $correctCallNumberFound = $callNumber;
                        $sf084a->content( $callNumber );
                        $statistics->{callNumberRepaired}++;
                    }
                    elsif ($resolution eq 'OK') {
                        #Rejoice!
                    }
                    else {
                        print("Record '".$r->docId()."' using Call number '".$sf084a->content()."', unknown call number repair resolution '$resolution'\n");
                    }
                }
            }
        }
    }
    unless ($correctCallNumberFound) {
        if (my $f090a = $r->fields('090')) {
            foreach my $f090 (@$f090a) {
                if (my $sf090aa = $f090->subfields('a')) {
                    for (my $i=0 ; $i<scalar(@$sf090aa) ; $i++) {
                        my $sf090a = $sf090aa->[$i];

                        my ($resolution, $callNumber) = repairCallNumber( $sf090a->content() );
                        if ($resolution eq 'OK' || $resolution eq 'FIX') {
                            my $sf084a = $r->getUnrepeatableSubfield('084', 'a');
                            unless ($sf084a) {
                                $sf084a = $r->addUnrepeatableSubfield('084', 'a', $callNumber);
                            }
                            else {
                                $sf084a->content($callNumber);
                            }
                            $statistics->{callNumberSalvagedFrom090}++;
                        }
                    }
                }
            }
        }
    }
    $r->deleteFields('090');
    my $sf084a = $r->getUnrepeatableSubfield('084', 'a');
    $r->deleteFields('084') unless $sf084a; #Drop 084 if it is empty.
}

sub enableComponentPartNoteController773i1 {
    my ($r) = @_;

    if (my $f773a = $r->fields('773')) {
        foreach my $f773 (@$f773a) {
            my $i1 = $f773->indicator1();
            unless ($i1 && $i1 eq '0') {
                $f773->setIndicator1('0');
                $statistics->{enableComponentPartNoteController773i1}++;
            }
        }
    }
}

sub printStatistics {
    my $count = 0;
    my $report = "\n\nMarcRepair statistics\n";
    for my $action (sort keys %$statistics) {
        $report .= $action.':'.$statistics->{$action}.'   '."\n";

        $count += $statistics->{$action};
    }
    print($report . 'TOTAL:' . $count) . "\n\n";
}


return 1; #to make compiler happy happy
