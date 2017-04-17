package MMT::Repository::HashRepository;

use warnings;
use strict;
use utf8;

=head1 SYNOPSIS
indexes start from zero(0)
$param1/filePath define the file to load data from
$param2/pk define the primary key column index.
$param3/column the column you want to be extracted

On creation the Repository-object loads the given file to a 'data'-array inside the object hash.
Primary key(pk) is the index in the array and the desired columns have been concatenated to the array index.
=cut

sub createRepository {
	my $startTime = time();
	
	my $class = shift;
	my $self = {@_};
	if(! exists($self->{'filePath'})) {
		warn "HashRepository filePath not defined.";
		return undef;
	}
	if(! exists($self->{'pk'})) {
		warn "HashRepository pk(primary key) not defined.";
		return undef;
	}
	if(! exists($self->{'column'})) {
		warn "HashRepository column not defined.";
		return undef;
	}
	if(! exists($self->{'logger'})) {
		warn "HashRepository logger not defined.";
		return undef;
	}

	$self->{'fileBasename'} = File::Basename::basename($self->{'filePath'});

	print "\nHashRepository on  ",$self->{'filePath'};
	
	bless($self, $class);

	$self->loadFile();
	
	print "\nTime taken " . (time() - $startTime) . "seconds \n";
	
	return $self;
}

sub loadFile {
	my $self = shift;
	my $DEBUGAuthCountLimit = $CFG::CFG->{'DEBUGAuthoritiesCountLimit'}; #Limits how many authorities are loaded, use something <=0 to load the whole repo
	my %columns;
	
	open LICAUTH, "<:utf8", $self->{'filePath'} or die $!;
	
	my $authCount = 0;
	my @strip; #used to store the row data;
	while (<LICAUTH>) {
		if(length($_) < 3) {
			next;
		}
        
		#check if enough Hashehs have been loaded to the repo
		if ( $DEBUGAuthCountLimit > 0 && $authCount++ > $DEBUGAuthCountLimit ) {
			last();
		}
        
		@strip = split '\t', $_;

		$columns{sanitize( $strip[$self->{'pk'}] )} = sanitize(  $strip[$self->{'column'}]  );
	}
	
	close(LICAUTH);
	
	$self->{'data'} = \%columns;
}

=head1 SYNOPSIS
Serves as a sanitization junction for different sanitizing operations
@param1 pointer to the line of text to sanitize
=cut
sub sanitize {
	my $text = shift;
	$text =~ s/\s*$//;
	$text =~ s/^\s*//;

	return $text;
}

=head1 SYNOPSIS
@param1 pointer to the string whose starting numbers need to be removed
=cut
sub removeLengthIndicator {
	my $text = shift;
	$$text =~ s/^ *\d?\d?//;
}
sub trim {
	$_[0] =~ s/^\s*//;
	$_[0] =~ s/\s*$//;
	return $_[0];
}

#fetches a designated key from one authority record, or the whole stored authority record.
sub fetch {
    #lock $_[0]->[$_[1]];
    my $self = $_[0];
    my $pk = $_[1];
    
    if ($pk) {
	my $retval = $self->{data}->{$pk};
	if (! defined $retval) {
		$self->{logger}->warning('No authority for pk = '.$pk);
		return '';
	}
	return $retval;
    }
}
sub fetchWithoutAlert {
	my $self = $_[0];
    my $pk = $_[1];
    
    if ($pk) {
		my $retval = $self->{data}->{$pk};
		if (! defined $retval) {
			return undef;
		}
		else {
			return $retval;
		}
    }
}

#return true to make compiler happy!
1;