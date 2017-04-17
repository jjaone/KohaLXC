package MMT::MARC::Subfield;

use Modern::Perl;

use MMT::MARC::Field;
use MMT::MARC::Record;

=head1 SYNOPSIS

=cut
sub new {
    my $class = $_[0];
    my $self = {};
    bless($self, $class);

    code($self, $_[1]) if (exists $_[1]);
    content($self, $_[2]) if (exists $_[2]);

    return $self;
}

sub code {
    my $self = shift;
    my $code = shift;

    if ($code) {
        #Some subfield codes are upper case, which is a bitch, but this fixes it.
        $code = lc $code;

        if (! defined $self->{code}) {
            $self->{code} = $code;
        }
        elsif (! ($self->{code} eq $code) ) {
            my $oldCode = $self->{code};
            $self->{code} = $code;
            $self->parent()->relocateSubfield($oldCode, $self);
        }
    }
    return $self->{code};
}
sub content {
    my $self = shift;
    my $content = shift;

    my $maxWordLength = $CFG::CFG->{Biblios}->{MaxWordLength};

    if (defined $content) {
        if ($content =~ /\S{$maxWordLength,}/) { #Zebra indexer dies if single words inside subfields are too long. It is also most certainly an error if such a thing happens.
            if (ref $self ne 'MMT::MARC::Subfield') {
                my $dbg = 1;
            }
            else {
                my $field = $self->parent() if $self;
                my $record = $field->parent() if $field;
                my $docid = $record->docId() if $record;
                print 'MARC::Subfield->content(): Subfield word is too long with over "'.$maxWordLength.'" characters. Subfield word is removed.'."\n".
                      (($docid) ? 'Record docId: "'.$docid.'",' : '' ).
                      (($field) ? 'Field code: "'.$field->code().'",' : '' ).
                      (($self && $self->code()) ? 'Subfield code: "'.$self->code().'",' : '' )."  bad content follows:\n".
                      $content;
                $content =~ s/\S{$maxWordLength,}//gsm;
            }
        }
        $self->{content} = $content;
    }
    return $self->{content};
}
sub contentXMLEscaped {
    my ($self) = @_;
    my $c = $self->{content};
    $c =~ s/&/&amp;/sg;
    $c =~ s/</&lt;/sg;
    $c =~ s/>/&gt;/sg;
    $c =~ s/"/&quot;/sg;
    return $c;
}
sub parent {
    my $self = shift;
    my $parent = shift;
    
    if ($parent) {
        $self->{parent} = $parent;
    }
    return $self->{parent}; 
}

sub DESTROY {
    my $self = shift;
    
    foreach my $k (keys %$self) {
        $self->{$k} = undef;
        delete $self->{$k};
    }
    undef %$self;
    undef $self;
}

#Make compiler happy
1;