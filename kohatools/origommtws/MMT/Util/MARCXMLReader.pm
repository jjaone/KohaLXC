package MMT::Util::MARCXMLReader;

use Modern::Perl;

use XML::Simple;
use MMT::MARC::Record;

=head

    my $fr = MMT::Util::XMLReader->new({sourceFile => 'Kirkas/MARC21.raw.xml'});

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    $self->{_config} = $params;
    $self->{verbose} = $params->{verbose} || 0;
    bless $self, $class;

    my $fh = eval { local *FH; open( FH, '<:encoding(utf8)', $self->{_config}->{sourceFile} ) or die; *FH{IO}; };
    if ( $@ ) {
        die "Couldn't open ".$self->{_config}->{sourceFile}.": $@";
        return;
    }
    $self->{ fh } = $fh;

    return $self;
}

sub next {
    my $self = shift;
    my $fh = $self->{ fh };

    ## return undef at the end of the file
    if (eof($fh)) {
        close $fh;
        return;
    }

    ## get a chunk of xml for a record
    my $xml;
    {
        local $/ = 'record>';
        $xml = <$fh>;
    }

    ## do we have enough?
    $xml .= <$fh> if $xml !~ m!</([^:]+:){0,1}record>$!;
    ## trim stuff before the start record element 
    $xml =~ s/.*?<(([^:]+:){0,1})record.*?>/<$1record>/s;

    ## return undef if there isn't a good chunk of xml
    return if ( $xml !~ m|<(([^:]+:){0,1})record>.*</\1record>|s );

    ## if we have a namespace prefix, restore the declaration
    if ($xml =~ /<([^:]+:)record>/) {
        $xml =~ s!<([^:]+):record>!<$1:record xmlns:$1="http://www.loc.gov/MARC21/slim">!;
    }

    $xml = XML::Simple::XMLin( $xml );
    my $marc = MMT::MARC::Record->newFromXml($xml);
    return( $marc );
}

sub _parser {
    my ($self) = @_;

    $self->{parser} ||= XML::LibXML->new(
        ext_ent_handler => sub {
            die "External entities are not supported\n";
        }
    );
    return $self->{parser};
}

1;
