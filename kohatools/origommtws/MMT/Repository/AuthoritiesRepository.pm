package MMT::Repository::AuthoritiesRepository;

use warnings;
use strict;

use File::Basename;

=head1 SYNOPSIS
indexes start from zero(0)
$param1/filePath define the file to load data from
$param2/pk define the primary key column index.
$param3/columns a list of columns you want to be extracted where paired indexes
    contain the column index and pairless are the marc subfield code these
    columns should be put into. ex. [1,a,2,c,5,d]

On creation the Repository-object loads the given file to a 'data'-array inside the object hash.
Primary key(pk) is the index in the array and the desired columns have been concatenated to the array index.

STRUCTURE OF A AUTHORITY REPOSITORY
$repository->[$pks]->{$keys}
       ->[the authorities row identified by its defined pk-column]->{Key names matching configured columns}
=cut

#Object constructor
sub createRepository {
    
    #lets time the duration taken
    my $startTime = time();
    
    my $class = shift;
    my $self = {@_};
    if(! exists($self->{'filePath'})) {
        warn "AuthoritiesRepository filePath not defined.";
        return undef;
    }
    if(! exists($self->{'pk'})) {
        warn "AuthoritiesRepository pk(primary key) not defined.";
        return undef;
    }
    if(! exists($self->{'columns'})) {
        warn "AuthoritiesRepository columns not defined.";
        return undef;
    }

    $self->{'fileBasename'} = File::Basename::basename($self->{'filePath'});

    print "\nAuthoritiesRepository on  ",$self->{'filePath'}."\n";
    
    bless($self, $class);

    $self->loadFile();
    
    print "\nTime taken " . (time() - $startTime) . "seconds \n";
    
    return $self;
}


sub loadFile {
    my $self = shift;
    my $DEBUGAuthCountLimit = $CFG::CFG->{'DEBUGAuthoritiesCountLimit'}; #Limits how many authorities are loaded, use something <=0 to load the whole repo
    my %columns;

    open my $LICAUTH, "<:utf8", $self->{'filePath'} or die $!;
    my $csv = Text::CSV_XS->new({eol => "\n"});

    my $authCount = 0; #Counts how many authorities have been loaded
    while (my $row = $csv->getline($LICAUTH)) {

        if ( $DEBUGAuthCountLimit > 0 && $authCount++ > $DEBUGAuthCountLimit ) {
            last();
        }

        my %content;
        #get the number of columns to be extracted
        my $cols = $self->{'columns'};

        #extract the marc subfield code to $key and the content to $val
        for(my $i=0 ; $i<@$cols ; $i+=2) {
            my $key = $cols->[$i+1];
            my $val = $row->[ $cols->[$i] ];
            $content{$key} = $val;
        }
        my $pk = $self->{pk};
        if (ref $pk eq 'ARRAY') {
            my $id = getKey($row->[ $pk->[0] ], $row->[ $pk->[1] ]);
            $columns{ $id } = {%content};
        }
        else {
            $columns{ $row->[ getKey($pk) ] } = {%content};
        }
    }

    close($LICAUTH);

    $self->{'data'} = \%columns;

    print "keys loaded: ". keys(%columns)."\n";
}


#fetches a designated key from one authority record, or the whole stored authority record.
sub fetch {
    #lock $_[0]->[$_[1]];
    my ($self, $pkOrig, $childId, $key, $noWarnings) = @_;

    my $retval;

    my $pk = getKey( $pkOrig, $childId );
    if ($key) {
        $retval = $self->{data}->{$pk}->{$key};
    }
    else {
        $retval = $self->{data}->{$pk};
    }

    #If we are unlucky and cannot find authorities data with the combined key of docId+childId, we can try again with just the docId
    # This seems to be the case for 'pielinen'.
    if (not($retval) && $childId) {
        $pk = getKey( $pkOrig, $childId, 1 ); #Get only the $pk-portion
        if ($key) {
            $retval = $self->{data}->{$pk}->{$key};
        }
        else {
            $retval = $self->{data}->{$pk};
        }
    }

    if (! defined $retval) {
        print "No '".$self->{'fileBasename'}."' authority for pk = ".$pk.(($key) ? ', key = '.$key : '')."\n" unless $noWarnings;
        return undef;
    }
    else {
        return $retval;
    }
}

##Returns undef instead of ' ' if nothing is found
sub fetchWithoutWarning {
    #lock $_[0]->[$_[1]];
    my $self = $_[0];
    my $pk = $_[1];
    my $childId = $_[2];
    my $key = $_[3];
    
    return $self->fetch( $pk, $childId, $key, 1 ); #Request with no warnings!
}

=head getKey

    getKey($pk, $childId, $justPk);

Sometimes the key can be two-part. Parents biblionumber + the childId of a component part.

@PARAM3, Boolean, simply return only the given primary key and do not append the childId to it.
@RETURNS String, either $pk.'c'.$childId, for ex. "34325c12" or just the $pk, for ex. "34325"
=cut
sub getKey {
    my ($pk, $childId, $justPk) = @_;

    if (ref $pk eq 'ARRAY') {
        $childId = ($justPk) ? undef : $pk->[1];
        $pk = $pk->[0];
    }
    else {
        $childId = undef if $justPk;
    }

    if ($childId) {
        return $pk.'c'.$childId;
    }
    else {
        return $pk;
    }
}
#return true to make compiler happy!
1;