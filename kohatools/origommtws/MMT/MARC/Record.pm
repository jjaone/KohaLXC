package MMT::MARC::Record;

#Class to store bibliodata
=head2 DATA STRUCTURE

$Record =
{
    leader => {
	"LEADER TEXT STRING"
    },
    fields => {
        001 => [
            0 => {
                i1 => "1",
                i2 => "0",
                a => [
                    0   => "subfield content",
                    1 => "repeated subfield content",
                    n => "nth subfield content"
                ],
                x => [...]
            }
            n => {...}
        ]
        nnn => [...]
    }
}

=cut

use Modern::Perl;

use MMT::MARC::Field;
use MMT::MARC::Subfield;

use MMT::Biblios::MarcRepair;

use TranslationTables::material_code_to_itype;
use TranslationTables::isil_translation;


=head1 SYNOPSIS

=cut
sub new {
    my $class = shift;
    my $self = {@_};

    #initialize the owned fields reference array
    $self->{fields} = [];

    bless($self, $class);
    return $self;
}

sub newFromXml {
    my ($class, $xmlSimple) = @_;
    my $self = $class->new();

    $self->leader($xmlSimple->{leader});

    $xmlSimple->{controlfield} = [$xmlSimple->{controlfield}] unless ref $xmlSimple->{controlfield} eq 'ARRAY';
    foreach my $controlField (@{$xmlSimple->{controlfield}}) {
        $self->addUnrepeatableSubfield($controlField->{tag}, 'a', $controlField->{content});
    }

    $xmlSimple->{datafield} = [$xmlSimple->{datafield}] unless ref $xmlSimple->{datafield} eq 'ARRAY';
    foreach my $dataField (@{$xmlSimple->{datafield}}) {
        my $f = $self->addField($dataField->{tag});
        $f->setIndicator1($dataField->{ind1});
        $f->setIndicator2($dataField->{ind2});
        $dataField->{subfield} = [$dataField->{subfield}] unless ref $dataField->{subfield} eq 'ARRAY';
        foreach my $subField (@{$dataField->{subfield}}) {
            $f->addSubfield($subField->{code}, $subField->{content});
        }
    }

    return $self;
}

#Receives either a 3-digit field identifier or a MARC:Field-object
sub addField {
    my $self = shift;
    my $field = shift;
    my $fieldNumber;

    unless ($field) {
        print "Record '".$self->docId()."'. Trying to add field with no field code!\n";
        return undef;
    }

    #Make sure the storable object is a MARC::Field, if not then make one out of it, if possible
    unless (ref $field eq 'MMT::MARC::Field') {
        $field = MMT::MARC::Field->new($field);
    }

    if ( exists $self->{$field->code} && ref $self->{$field->code} eq 'ARRAY' ) {
        push @{$self->{$field->code}}, $field;
    }
    else {
        $self->{$field->code} = [$field];
    }

    #Set this MARC::Record as the parent of the newly created MARC::Field
    $field->parent($self);

    #update the owned fields reference list
    push @{$self->{fields}}, $field;
    return $field;

}
#PARAM1 = the field code, whose every instance is removed from this record, eg. '245'
sub deleteFields {
    my $self = shift;
    my $field = shift;

    if (defined $self->{$field} && ref $self->{$field} eq "ARRAY") {

	#iterate the owned fields reference list, {fields}, backwards so splicing the array causes no issues during iteration.
	for ( my $index = @{$self->{fields}}-1; $index >= 0; --$index ) {
	    splice( @{$self->{fields}}, $index, 1 ) if ($self->{fields}->[$index]->code() eq $field);
	}

	#Finalize the delete by removing hash->array references and DESTROY:ing the object
	while (my $delme = pop @{$self->{$field}}) {
	    $delme->DESTROY();
	    undef $delme;
	}
	delete $self->{$field};
    }
}
#param1 = the Field object reference
sub deleteField {
    my $self = shift;
    my $field = shift;
    my $code = $field->code();

    #remove the given field from the hash->array data structure
    for ( my $i = @{$self->{$code}}-1; $i >= 0; --$i ) {
	if ( $self->{$code}->[$i] eq $field) {
	    splice( @{$self->{$code}}, $i, 1 );
	    last();
	}
    }
    delete $self->{$code} if scalar @{$self->{$code}} == 0;

    #iterate the owned fields reference list, {fields}, backwards so splicing the array causes no issues during iteration.
    for ( my $index = @{$self->{fields}}-1; $index >= 0; --$index ) {
	if ($self->{fields}->[$index] eq $field) {
            splice( @{$self->{fields}}, $index, 1 );
            last();
        }
    }

    $field->DESTROY();
}
sub fields {
    my $self = shift;
    my $field = shift;

    if ($field) {
        return $self->{$field} if exists $self->{$field};
		return undef;
    }
    return $self->getAllFields();
}
sub getAllFields {
    my $self = shift;
    my $as_sorted = shift;

    return $self->{fields} if (! $as_sorted);

    if (@{$self->{fields}} > 1) {

        $self->{fields} = [sort {$a->{fieldNumber} cmp $b->{fieldNumber}} @{$self->{fields}}];
        return $self->{fields};
    }
    return $self->{fields};

}
sub getAllSubfields {
    my $self = shift;
    my $fieldCode = shift;
    my $subfieldCode = shift;

    my $subfields = [];

    if ($fieldCode && $subfieldCode) {
        if (my $fs = $self->fields($fieldCode)) {
            foreach ( @$fs ) {
                next if (! (defined($_->subfields($subfieldCode))) );
                foreach ( @{$_->subfields($subfieldCode)} ) {
                    push @$subfields, $_;
                }
            }
        }
    }
    else {
        foreach ( @{$self->{fields}} ) {
            foreach ( $_->getAllSubfields() ) {
                push @$subfields, @$_;
            }
        }
    }

    return $subfields;
}
sub docId {
    my $self = shift;
    my $docId = shift;

    if ($docId) {
		$self->{docId} = $docId;

		#save the docid as the 001-field
		my $target = $self->getUnrepeatableSubfield('001','a');
		if (! (defined $target)) {
			$target = MMT::MARC::Field->new("001");
			$target->addSubfield("a", $docId);
			$self->addField(  $target  );
		}
		##replace the old one if exists
		else {
			$target->content($docId);
		}
    }
    elsif (not($self->{docId})) {
        my $target = $self->getUnrepeatableSubfield('001','a');
        $self->{docId} = $target->content() if $target;
    }
    return $self->{docId};
}
sub publicationDate {
    my ($self, $publicationDate) = @_;

    if ($publicationDate) {
        my $sf008 = $self->getUnrepeatableSubfield('008','a');
        if ($sf008 && $sf008->content() =~ /^(.{7}).{4}(.+)$/) {
            $sf008->content( $1.$publicationDate.$2 );
        }
        else {
            $self->addUnrepeatableSubfield('008', 'a', "       $publicationDate    ");
        }
        $self->{publicationDate} = $publicationDate;
        return $publicationDate;
    }
    unless ($self->{publicationDate}) {
        my $sf008 = $self->getUnrepeatableSubfield('008','a');
        if ($sf008 && $sf008->content() =~ /^.{7}(\d{4}).+$/) {
            $self->{publicationDate} = $1;
        }
    }

    return $self->{publicationDate} || '';
}
sub status {
    my $self = shift;
    my $status = shift;

    $self->{status} = $status if defined $status;
    return $self->{status};
}
sub childId {
    my $self = shift;
    my $childId = shift;

    $self->{childId} = $childId if defined $childId;
    return $self->{childId};
}
sub marcFormat {
    my $self = shift;
    my $marcFormat = shift;

    $self->{marcFormat} = $marcFormat if defined $marcFormat;
    return $self->{marcFormat};
}
sub modTime {
    my $self = shift;
    my $modTime = shift;

    if ($modTime) {
		$self->{modTime} = $modTime;

		#save the docid as the 001-field
		my $target = $self->getUnrepeatableSubfield('005','a');
		if (! (defined $target)) {
			$target = MMT::MARC::Field->new("005");
			$target->addSubfield("a", $modTime);
			$self->addField(  $target  );
		}
		##replace the old one if exists
		else {
			$target->content($modTime);
		}
    }
    return $self->{modTime};
}
sub dateReceived {
    my $self = shift;
    my $dateReceived = shift;

    if ($dateReceived) {
		$self->{dateReceived} = $dateReceived;

		#save the docid as the 001-field
		my $target = $self->getUnrepeatableSubfield('942','1');
		if (! (defined $target)) {
			$target = $self->addUnrepeatableSubfield('942','1', $dateReceived);
		}
		##replace the old one if exists
		else {
			$target->content($dateReceived);
		}
    }
    return $self->{dateReceived};
}
sub rowId {
    my $self = shift;
    my $rowId = shift;

    $self->{rowId} = $rowId if defined $rowId;
    return $self->{rowId};
}
sub pallasLabel {
    my $self = shift;
    my $pallasLabel = shift;

    $self->{pallasLabel} = $pallasLabel if $pallasLabel;
    return $self->{pallasLabel};
}
sub leader {
    my $self = shift;
    my $leader = shift;

    $self->{leader} = $leader if $leader;
    return $self->{leader};
}
sub signum {
    my $self = shift;

    unless ($self->{signum}) {
        #Get the proper SIGNUM (important) Use one of the Main Entries or the Title Statement
        my $leader = $self->leader(); #If this is a video, we calculate the signum differently, 06 = 'g'
        my $signumSource; #One of fields 100, 110, 111, 130, or 245 if 1XX is missing
        my $nonFillingCharacters = 0;

        if (substr($leader,6,1) eq 'g' && ($signumSource = $self->getUnrepeatableSubfield('245', 'a'))) {
            $nonFillingCharacters = $signumSource->parent()->indicator2();
        }
        elsif ($signumSource = $self->getUnrepeatableSubfield('100', 'a')) {

        }
        elsif ($signumSource = $self->getUnrepeatableSubfield('110', 'a')) {

        }
        elsif ($signumSource = $self->getUnrepeatableSubfield('111', 'a')) {

        }
        elsif ($signumSource = $self->getUnrepeatableSubfield('130', 'a')) {
            $nonFillingCharacters = $signumSource->parent()->indicator1();
            $nonFillingCharacters = 0 if (not(defined($nonFillingCharacters)) || $nonFillingCharacters eq ' ');
        }
        elsif ($signumSource = $self->getUnrepeatableSubfield('245', 'a')) {
            $nonFillingCharacters = $signumSource->parent()->indicator2();
        }
        if ($signumSource) {
            $self->{signum} = uc(substr($signumSource->content(), $nonFillingCharacters, 3));
        }
    }
    return $self->{signum};
}
sub materialType {
    my $self = shift;
    my $matType = shift;

#    my $f245a = $self->getUnrepeatableSubfield('245','a');
#    if ($f245a && $f245a->content =~ /Ella ja Paterock/) {
#        my $break = 1;
#    }


    if ($matType) {
        my $itype = TranslationTables::material_code_to_itype::fetch($matType);
        if (defined $itype && exists $itype->[0]) {
            $self->isASerial(1) if exists $itype->[1] && $itype->[1] == 1;
            my $newMatType = $itype->[0];

            $newMatType = MMT::Biblios::MarcRepair::convertAanikirjaItemtype($self, $newMatType);
            $newMatType = MMT::Biblios::MarcRepair::convertYleItemTypes($self, $newMatType);

            $self->{materialType} = $newMatType;
            $self->addUnrepeatableSubfield('942', 'c', $newMatType); #Store the Koha 942$c default itemtype already.

            if ($self->{materialType} eq 'DELETE') {
                print "Record docId:".$self->docId()." material type: 'DELETE'. Deleting record.\n";
                die 'DELETE';
            }
        }
        else {
            print "Record docId:".$self->docId()." has a bad material type:".$matType."\n";
            return undef;
        }
    }
    return $self->{materialType};
}
sub countryOfOrigin {
    my $self = shift;
    my $coo = shift;

    $self->{countryOfOrigin} = $coo if $coo;
    return $self->{countryOfOrigin};
}
#These records are finally deleted during Component Part and Multirecord merging in SharedDocidRecordsHandler()
sub markAsDeleted {
    my $self = shift;
    $self->{deleted} = 1;
}
sub isDeleted {
    my $self = shift;

    if (exists $self->{deleted}) {
        return 1;
    }
    return 0;
}
sub isComponentPart {
    my $self = shift;

    return $self->getComponentParentDocid();
}
sub getComponentParentDocid {
    my $self = shift;
    if (my $f773w = $self->getUnrepeatableSubfield('773','w')) {
        return $f773w->content();
    }
    return 0;
}
sub isASerial {
    my $self = shift;
    my $ias = shift;

    if (defined $ias) {
        if ($ias == 1) {
            $self->{isASerial} = 1;
        }
        elsif ($ias == 0) {
            delete $self->{isASerial} if $ias == 0;
        }
    }

    return (exists $self->{isASerial}) ? 1 : 0;
}
sub isASerialMother {
    my $self = shift;
    my $ias = shift;

    if (defined $ias) {
        if ($ias == 1) {
            $self->{isASerialMother} = 1;
        }
        elsif ($ias == 0) {
            delete $self->{isASerialMother} if $ias == 0;
        }
    }

    return (exists $self->{isASerialMother}) ? 1 : 0;
}

sub addUnrepeatableSubfield {
    my $self = shift;
    my $fieldCode = shift;
    my $subfieldCode = shift;
    my $subfieldContent = shift;

    unless ($fieldCode) {
        print "Record '".$self->docId()."'. Trying to add subfield with no field code!\n";
        return undef;
    }
    unless ($subfieldCode) {
        print "Record '".$self->docId()."'. Trying to add subfield for field '$fieldCode', but no subfield code!\n";
        return undef;
    }
    unless ($subfieldContent) {
        print "Record '".$self->docId()."'. Trying to add subfield for field '$fieldCode', subfield '$subfieldCode', but no subfield content!\n";
        return undef;
    }

    if (my $sf = $self->getUnrepeatableSubfield($fieldCode, $subfieldCode)) {
        $sf->content( $subfieldContent );
        return $sf;
    }
    else {
        my $f = $self->getUnrepeatableField( $fieldCode );
        if (! $f) {
            $f = MMT::MARC::Field->new( $fieldCode ) ;
            $self->addField($f);
        }

        my $sf = MMT::MARC::Subfield->new( $subfieldCode, $subfieldContent );
        $f->addSubfield($sf);
        return $sf;
    }
}

sub getUnrepeatableSubfield {
    my $self = shift;
    my $fieldCode = shift;
    my $subfieldCode = shift;

    return undef if (! (defined $self->fields($fieldCode)) );
    foreach ( @{$self->fields($fieldCode)} ) {

        return undef if (! (defined $_->subfields($subfieldCode)) );
        foreach ( @{$_->subfields($subfieldCode)} ) {
            return $_;
        }
    }
}

sub getUnrepeatableField {
    my $self = shift;
    my $fieldCode = shift;

    my $fields = $self->fields($fieldCode);
    return undef if (! (defined $fields) );
    return $fields->[0];
}

#If Subfield's code changes, we need to move it to another hash bucket.
sub relocateField { #params: ->($oldCode, $MARC::Subfield)
    my $self = shift;
    my $oldCode = shift;
    my $f = shift;

    my $removeFieldFromArray;
    $removeFieldFromArray = sub {
        for ( my $i=0; $i < @{$self->{$_[0]}} ; $i++ ) {
            if ($f eq $self->{$_[0]}->[$i]) {
                splice @{$self->{$_[0]}},$i,1;

                delete $self->{$_[0]} if (  @{$self->{$_[0]}} == 0  );

                last;
            }
        }
    };

    #find the same object reference inside the codes hash bucket, and delete it
    &$removeFieldFromArray($oldCode);
    #find the same object reference inside the subfields array, and delete it
    &$removeFieldFromArray("fields");

    $self->addField($f);
}

sub getCallNumber() {
    my $self = shift;
    my $callNumber; #Try to fetch it from default ISIL, but if it is not available, any library will do.

    my $f852a = $self->fields('852');
    my $defaultIsil = TranslationTables::isil_translation::GetDefaultIsil();
    foreach my $f852 (@$f852a) {
        if (my $sfa = $f852->getUnrepeatableSubfield('a') ) {
            if ($sfa->content() eq $defaultIsil) {
                my $sfh = $f852->getUnrepeatableSubfield('h');
                $callNumber = $sfh->content();
                last();
            }
        }
    }
    if (! $callNumber) {
        if (my $sfh = $self->getUnrepeatableSubfield('852','h') ) {
            $callNumber = $sfh->content();
        }
    }
    return $callNumber;
}
sub getCallNumberClass() {
    my $self = shift;
    my $callNumber = $self->getCallNumber();
    if (defined $callNumber && $callNumber =~ /^(\d+)/) {
        $callNumber = $1;
        return $callNumber;
    }
    else {
        my $breakpoint;
    }
}

#delete everything inside this record. Perl refuses to GC these MARC::Records, because of a circular reference from MARC::Subfield -> MARC::Field -> MARC::Record.
#We need to manyally hard destroy these mofos!
sub DESTROY {
    my $self = shift;

    foreach my $k (keys %$self) {

        if (ref $self->{$k} eq "ARRAY") {
            my $array = $self->{$k};
            for(my $i=0 ; $i < @{$array} ; $i++) {
                if (ref $array->[$i] eq "MMT::MARC::Field") {
                    $array->[$i]->DESTROY();
                }
                undef $array->[$i];
            }
        undef @{$self->{$k}};
        }

    undef $self->{$k};
        delete $self->{$k};
    }
    undef %$self;
    undef $self;
}


#Make compiler happy
1;
