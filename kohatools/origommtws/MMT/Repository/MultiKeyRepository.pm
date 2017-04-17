package Repository::MultiKeyRepository;

use strict;
use warnings;
use utf8;

use CommonRoutines;

sub createRepository {
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
	if(! exists($self->{'logger'})) {
		warn "AuthoritiesRepository logger not defined.";
		return undef;
	}

	$self->{'fileBasename'} = File::Basename::basename($self->{'filePath'});

	print "\nMultiKeyRepository on  ",$self->{'filePath'};
	
	bless($self, $class);

	$self->loadFile();
	
	print "\nTime taken " . (time() - $startTime) . "seconds \n";
	
	return $self;

}
sub loadFile {
	my $self = shift;
    my $DEBUGAuthCountLimit = $CFG::CFG->{'DEBUGAuthoritiesCountLimit'}; #Limits how many authorities are loaded, use something <=0 to load the whole repo
	my $columns = {};
	my @targetColumns;
	
	open LICAUTH, "<:utf8", $self->{'filePath'} or die $!;
	
    my $authCount = 0;
	while (<LICAUTH>) {
		if(length($_) < 3) {
			next;
		}
        
		if ( $DEBUGAuthCountLimit > 0 && $authCount++ > $DEBUGAuthCountLimit ) {
			last();
		}
		
		my @row;
		foreach(split('\t', $_)) {
			push @row, trim($_);
		};
		
		#extract the desired columns
		for(my $i=0 ; $i< scalar @{$self->{'columns'}} ; $i++) {
			$targetColumns[$i] = $row[$self->{'columns'}->[$i]];
		}
		
		#build the multikey referencing tunnel. Using a reverse recursion.
		my $pkLength = @{$self->{'pk'}};
		my $previousLevel; #pointer to previous key layer
		if (exists $columns->{  $row[ $self->{'pk'}->[0] ]  } ) {
			$previousLevel = \$columns->{  $row[ $self->{'pk'}->[0] ]  };
		}
		else {
			$columns->{  $row[ $self->{'pk'}->[0] ]  } = {};
			$previousLevel = \$columns->{  $row[ $self->{'pk'}->[0] ]  };
		}
		for(1..$pkLength-1) {
			if (exists $$previousLevel->{  $row[ $self->{'pk'}->[$_] ]  } ) {
				$previousLevel = \$$previousLevel->{  $row[ $self->{'pk'}->[$_] ]  };
			}
			else {
				$$previousLevel->{  $row[ $self->{'pk'}->[$_] ]  } = {};
				$previousLevel = \$$previousLevel->{  $row[ $self->{'pk'}->[$_] ]  };
			}
			
		}
		#this row gets repeated really annoying errors:
		#Argument "" isn't numeric in array element at ItemsInjector/MultiKeyRepository.pm line 76, <LICAUTH> line 5.
		#once for every row in the file.
		#solved by simply hiding errors as this propably was a really important part of the complex reverse recursion algorithm
		no warnings;
		$$previousLevel = [ $targetColumns[0..@targetColumns] ];
		use warnings;
				
	}
	
	close(LICAUTH);
	
	$self->{'data'} = $columns;
		saveToFile($self);
}

#fetches a designated key from one authority record, or the whole stored authority record.
sub fetch {
    #lock $_[0]->[$_[1]];
    my $self = $_[0];
    my $key1 = $_[1];
    my $key2 = $_[2];
    my $key3 = $_[3];
    my $key4 = $_[4];
    
    if (defined $key1 && defined $key2 && defined $key3 && defined $key4) {
	return $self->{data}->{$key1}->{$key2}->{$key3}->[$key4];
    }
    return undef;
}

=head1 SYNOPSIS
@param1 pointer to the line to extract from
@param2 the column to extract starting from zero(0)
=cut
sub getColumn {
	my $line = $_[0];
	my $column = $_[1]-1;
	
	my @strip = ( $line =~ m/(.*?[\t|\n]){$column}(.*?\t|\n)/ );
	return $strip[1];
}

sub trim {
	$_[0] =~ s/^\s*//;
	$_[0] =~ s/\s*$//;
	return $_[0];
}

#HAS NOTHING TO DO WITH MIGRATING BIBLIOS, A SINGLE USE UTILITY
#Used to create a internal representation of liqlocde org_units.
#This is used for org_unit translation from PP to the new EG org_unit hierarchy.
#liqlocde_translator.pm gives translations on demand
sub saveToFile {
    
    my $data = $_[0]->{data};
    
    open TEMP,'>:utf8','/tmp/liqlocde.kir';
    select((select(TEMP), $|=1)[0]); #make filehandle hot!

    print TEMP "my \$org_units = {\n";
    
    foreach my $libid (sort {$a <=> $b} keys %$data) {
	
	next if (ref $libid eq 'HASH');
	
	print TEMP $libid . " => {\n";
	
	foreach my $locid ( sort {$a <=> $b} keys %{$data->{$libid}} ) {
		
	    next if (ref $locid eq 'HASH');
		
	    print TEMP "    " . $locid . " => {\n";
	    
	    foreach my $depid ( sort {$a <=> $b} keys %{$data->{$libid}->{$locid}} ) {
		
		next if (ref $depid eq 'ARRAY');
		
		print TEMP "        " . $depid . " => [ ";
		
		foreach my $code ( @{$data->{$libid}->{$locid}->{$depid}} ) {
			
		    print TEMP "'".$code."' , '' ],\n";
		}
		
	    }
	    print TEMP "    },\n";
	}
	print TEMP "},\n";
    }
    
    print TEMP "}\n";
    
=head        
    use Data::Dumper;

    $Data::Dumper::Indent = 1;
    $Data::Dumper::Purity = 1;
    
    print TEMP Data::Dumper::Dumper($data);
=cut    
    close TEMP;
}

#return true to make compiler happy!
1;