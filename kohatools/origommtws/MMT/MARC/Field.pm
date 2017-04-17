package MMT::MARC::Field;

use Modern::Perl;

use MMT::MARC::Subfield;
use MMT::MARC::Record;

=head1 SYNOPSIS

=cut
sub new {
    #my @debug = @_;
    my $class = $_[0];
    my $self = {};
    
    setCode($self, $_[1]) if (exists $_[1]);
    
    #initialize the owned subfields reference array
    $self->{subfields} = [];
    
    bless($self, $class);
        
    return $self;
}

sub setCode {
    my $self = $_[0];
    my $code = $_[1];
    
    if (exists $self->{fieldNumber} && $self->{fieldNumber} ne $code) {
        
        my $oldCode = $self->{fieldNumber};
        $self->{fieldNumber} = ($code =~ m/^\d\d\d$/) ? $code : die "$!\nERROR: given fieldNumber $code is not 3-digits!\n"; #duplicate code
        $self->parent()->relocateField($oldCode, $self);
    }
    else {
        $self->{fieldNumber} = ($code =~ m/^\d\d\d$/) ? $code : die "$!\nERROR: given fieldNumber $code is not 3-digits!\n"; #duplicate code
    }
}
sub code {
    my $self = shift;
    return $self->{fieldNumber};
}
sub addIndicators {
    
    my $self = shift;
    my @indicators = split(//, shift);
    
    for (my $i=0 ; $i<@indicators ; $i++) {
        if ($i > 1) {
            print "ERROR: Too many indicators in docId ".($self->parent() ? $self->parent()->docId() : 'NO_PARENT:(').", field ".$self->code().".\n";
            return 'TOOMANY';
        }
        $self->{"i".($i+1)} = $indicators[$i];
    }
}
sub setIndicator1 {
    my $self = shift;
    my $i1 = shift;
    $self->{i1} = defined($i1) ? $i1 : ' ';
}
sub indicator1 {
    my $self = shift;
    return $self->{i1} if defined $self->{i1};
    return " ";
}
sub setIndicator2 {
    my $self = shift;
    my $i2 = shift;
    $self->{i2} = defined($i2) ? $i2 : ' ';
}
sub indicator2 {
    my $self = shift;
    return $self->{i2} if defined $self->{i2};
    return " ";
}
sub addSubfield {
    my $self = $_[0];
    my $subfield_code = $_[1];
    my $sf;

    unless (defined($subfield_code)) {
        print "Record '".$self->parent->docId()."'. Trying to add subfield, but no subfield code!\n";
        return undef;
    }

    if (ref $subfield_code eq 'MMT::MARC::Subfield') {
        $sf = $subfield_code;
    }
    else {
        my $subfield_content = $_[2];
        unless (defined($subfield_content)) {
            print "Record '".$self->parent()->docId()."'. Trying to add subfield '$subfield_code' for field '".$self->code()."', but no subfield content!\n";
            return undef;
        }
        $sf = MMT::MARC::Subfield->new($subfield_code, $subfield_content);
    }
    
    if ( exists $self->{$sf->code} && ref $self->{$sf->code} eq 'ARRAY' ) {
        push @{$self->{$sf->code}}, $sf;
    }
    else {
        $self->{$sf->code} = [$sf];
    }
    
    #Set this MARC::Field as the parent of the newly created MARC::Subfield
    $sf->parent($self);
    
    #update the owned fields reference list
    push @{$self->{subfields}}, $sf;

    return $self;
}

sub subfields {
    my $self = shift;
    my $subfield = shift;
    
    if ($subfield) {
        return $self->{$subfield} if exists $self->{$subfield};
        return undef;
    }
    return undef;
}
sub getAllSubfields {
    my $self = shift;
    my $as_sorted = shift;
    
    return $self->{subfields} if (! $as_sorted);
    
    if (@{$self->{subfields}} > 1) {
        
        $self->{subfields} = [sort {$a->{code} cmp $b->{code}} @{$self->{subfields}}];
        return $self->{subfields};
    }
    return $self->{subfields};
}
sub getUnrepeatableSubfield {
    my $self = shift;
    my $subfieldCode = shift;
    my $sfa = $self->subfields($subfieldCode);
    
    return undef if (! (defined $sfa) );
    foreach ( @{$sfa} ) { #return the first instance, which should be the last as well
        return $_;
    }
}
sub parent {
    my $self = shift;
    my $parent = shift;
    
    if ($parent) {
        $self->{parent} = $parent;
    }
    return $self->{parent}; 
}
#If Subfield's code changes, we need to move it to another hash bucket.
sub relocateSubfield { #params: ->($oldCode, $MARC::Subfield)
    my $self = shift;
    my $oldCode = shift;
    my $sf = shift;
    
    my $removeSubfieldFromArray;
    $removeSubfieldFromArray = sub {
        for ( my $i=0; $i < @{$self->{$_[0]}} ; $i++ ) {
            if ($sf eq $self->{$_[0]}->[$i]) {
                splice @{$self->{$_[0]}},$i,1;
                
                delete $self->{$_[0]} if (  @{$self->{$_[0]}} == 0  );
                
                last;
            }
        }
    };
    
    #find the same object reference inside the codes hash bucket, and delete it
    &$removeSubfieldFromArray($oldCode);
    #find the same object reference inside the subfields array, and delete it
    &$removeSubfieldFromArray("subfields");
    
    $self->addSubfield($sf);
}

sub toText {
    my $self = shift;
    my $text = '';
    
    foreach my $sf (@{$self->getAllSubfields()}) {
        $text .= $sf->code()."\t".$sf->content()."\t";
    }
    return $text;
}
sub contentToText {
    my $self = shift;
    my $text = '';
    
    foreach my $sf (@{$self->getAllSubfields()}) {
        $text .= $sf->content()."\t";
    }
    return $text;
}

#param1 = the Subfield object reference
sub deleteSubfield {
    my $self = shift;
    my $subfield = shift;
    
    return 0 if (ref $subfield ne 'MMT::MARC::Subfield');
    
    my $code = $subfield->code();
    
    #remove the given field from the hash->array data structure
    for ( my $i = @{$self->{$code}}-1; $i >= 0; --$i ) {
    if ( $self->{$code}->[$i] eq $subfield) {
        splice( @{$self->{$code}}, $i, 1 );
        last();
    }
    }
    delete $self->{$code} if scalar @{$self->{$code}} == 0;
    
    #iterate the owned fields reference list, {fields}, backwards so splicing the array causes no issues during iteration.
    for ( my $index = @{$self->{subfields}}-1; $index >= 0; --$index ) {
    if ($self->{subfields}->[$index] eq $subfield) {
            splice( @{$self->{subfields}}, $index, 1 );
            last();
        }
    }
    
    $subfield->DESTROY();
    return 1;
}

=head mergeField

    $field->mergeField( $newField );

This method makes this Field copy another MARC::Field's subfields to itself.
When conflicting subfields are found, the new subfield is simply added by the existing
 subfield and a notification is printed.
@RETURNS String, if an error has hapened.
=cut
sub mergeField {
    my $self = shift;
    my $newField = shift;

    unless (ref $newField eq 'MMT::MARC::Field') {
        print "MARC::Field->mergeField($newField): \$newField is not a MARC::Field-object, for Biblio id '".($self->parent() ? $self->parent()->docId() : 'NO_PARENT:(')."' and Field '".$self->code()."'!\n";
        return 'ERROR';
    }

    my $newSfs = $newField->getAllSubfields();
    if ($newSfs) {
        foreach my $sf (@$newSfs) {
            if ($self->subfields( $sf->code() )) { #We already have subfields of this code
                print "MARC::Field->mergeField($newField): Subfield '".$sf->code()."' already exists, for Biblio id '".($self->parent() ? $self->parent()->docId() : 'NO_PARENT:(')."' and Field '".$self->code()."'. Adding it normally.\n";
            }

            my $sfCopy = MMT::MARC::Subfield->new($sf->code(), $sf->content());
            $self->addSubfield($sfCopy);
        }
    }
}

=head mergeAllSubfields

    $field->mergeAllSubfields($targetSubfield, $subfieldSeparator);
    $field->mergeAllSubfields($targetSubfieldCode, $subfieldSeparator);

Merges all subfields inside this field under the given subfield.
Contents are separated by the given separator.

@PARAM1,  MARC::Subfield or subfield code.
@PARAM2,  String
@RETURNS, "NOSUBFIELD", if no subfield is found.
          "OK", reference to the merged target subfield if merging happened.
          undef, if nothing to merge.

=cut
sub mergeAllSubfields {
    my ($self, $targetSubfield, $separator) = @_;
    $separator = ' - ' unless $separator;

    unless (ref $targetSubfield eq 'MMT::MARC::Subfield') {
        $targetSubfield = $self->getUnrepeatableSubfield( $targetSubfield );
    }
    unless ($targetSubfield) {
        return "NOSUBFIELD";
    }

    my $sfs = $self->getAllSubfields();
    my @mergeableContent;
    if ($sfs) {
        #Collect content and destroy the sibling subfields
        foreach my $sf (@$sfs) {
            if ($sf eq $targetSubfield) { #Don't merge target to itself!
                next();
            }

            my $content = $sf->content();
            push @mergeableContent, $content if $content && length $content > 0;
            $self->deleteSubfield($sf);
        }
        #Append the content to $targetSubfield
        if (scalar(@mergeableContent)) {
            $targetSubfield->content( $targetSubfield->content().$separator.join($separator, @mergeableContent) );
            return 'OK';
        }
    }
    return undef;
}

sub DESTROY {
    my $self = shift;
    
    foreach my $k (keys %$self) {
        
        if (ref $self->{$k} eq "ARRAY") {
            my $array = $self->{$k};
            for(my $i=0 ; $i < @{$array} ; $i++) {
                if (ref $array->[$i] eq "MMT::MARC::Subfield") {
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