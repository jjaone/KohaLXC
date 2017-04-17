package MMT::Repository::ArrayRepository;

use Modern::Perl;

use MMT::Util::CSVStreamer;

=head SYNOPSIS ArrayRepository

Is a base class (works also stand-alone without filtering) for reading/writing
.csv-files.
Reads the file to a HASH search table, and merges conflicting primary keys under
the same hash index in an array.

Extend it and overload prepareData() to do custom filtering.

@PARAM1 HASHRef, filename => 'source/Borrowers.csv'
                 ioOp => '<' || '>'  #Read or write to file
                 pkColumn => 0 || 1 || n #Which column index is the primary key used for searching.
                 columns => [1,3,5] #Which columns to extract, defaults to every column. You can use this with very big tables.

=cut

sub createRepository {
    my ($class, $params) = @_;
    my $self = {};
    bless($self, $class);
    $self->{filename} = $params->{filename};
    $self->{ioOp} = $params->{ioOp};
    $self->{pkColumn} = $params->{pkColumn} || 0;
    $self->{columns} = $params->{columns} || undef;

    my $startTime = time();

    $self->{'fileBasename'} = File::Basename::basename($self->{filename});

    print "\n$class on ".$self->{filename}." for operation '".$self->{ioOp}."'\n";

    bless($self, $class);

    $self->loadFromPregeneratedFile() if $self->{ioOp} eq '<';
    $self->openForWriting() if $self->{ioOp} eq '>';

    print "\nTime taken " . (time() - $startTime) . "seconds \n";
    return $self;
}

sub prepareData {
    my ($self, $data) = @_;
    ##THIS IS MEANT TO BE OVERLOADED FROM SUBCLASSES
    if ($self->{columns}) {
        my @data;
        foreach my $i (@{$self->{columns}}) {
            push @data, $data->[$i];
        }
        return \@data;
    }

    return $data;
}

sub put {
    my ($self, $data) = @_;
    $data = $self->prepareData($data);
    $self->{csv}->put($data);
}

sub loadFromPregeneratedFile {
    my $self = shift;
    my $DEBUGAuthCountLimit = $CFG::CFG->{'DEBUGAuthoritiesCountLimit'}; #Limits how many authorities are loaded, use something <=0 to load the whole repo
    my %columns;

    my $csvStreamer = MMT::Util::CSVStreamer->new($self->{'filename'}, '<');

    my $authCount = 0; #Counts how many authorities have been loaded
    while (my $row = $csvStreamer->next()) {

        if ( $DEBUGAuthCountLimit > 0 && $authCount++ > $DEBUGAuthCountLimit ) {
            last();
        }
        my $pk = $self->_popPrimaryKey($row); #Pop the top value which is the ID which is already the hash key :)

        #If we get shared ID's just put the values side-by-side
        if ($columns{$pk}) {
            if(ref($columns{$pk}) eq 'ARRAY' && ref($columns{$pk}->[0]) eq 'ARRAY') {
                push @{$columns{$pk}}, $row;
            }
            else {
                $columns{$pk} = [$columns{$pk}, $row];
            }
        }
        else {
            $columns{$pk} = $row;
        }
    }

    $csvStreamer->close();
    $self->{'data'} = \%columns;
}

sub openForWriting {
    my ($self) = @_;

    my $csvStreamer = MMT::Util::CSVStreamer->new($self->{filename},
                                                  '>');
    $self->{csv} = $csvStreamer;
}

#fetches a designated key from one authority record, or the whole stored authority record.
sub fetch {
    #lock $_[0]->[$_[1]];
    my $self = $_[0];
    my $pk = $_[1];
    my $key = $_[2] if $_[2];

    if ($key) {
        my $retval = $self->{data}->{$pk}->[$key];
            if (! defined $retval) {
                #$self->{logger}->warn('No authority for pk = '.$pk.', key = '.$key);
                return undef;
            }
        return $retval;
    }
    else {
        return $self->{data}->{$pk};
    }
}

sub _popPrimaryKey {
    my ($self, $column) = @_;
    my $pk = $column->[$self->{pkColumn}];
    #splice(@$column, $self->{pkColumn}, 1);
    return $pk;
}

#return true to make compiler happy!
1;
