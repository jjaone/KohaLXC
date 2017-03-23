package History;

use warnings;
use strict;
#use diagnostics;
use utf8;

use Switch;
use Data::Dumper;
use LiteLogger;

use CommonRoutines;
use TranslationTables::liqlocde_translation;

my $log;
sub initPackageVariables {
    $log = LiteLogger->new({package => 'Checkout'});
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Purity = 1;
}

=head1 SYNOPSIS
Container for item fields. Accessors use validators to make sure data is valid.
Fields must correspond to Instructions.pm
=cut
sub new {
    my $class = shift;
    my $s = {};

    bless($s, $class);
    return $s;
}
sub newFromRow {
    my $class = shift;
    no strict 'vars';
    eval shift;
    my $s = $VAR1;
    use strict 'vars';
    warn $@ if $@;
    return $s;

}

#setters receive self as $_[0]
# the CheckoutsInjectChain::Reader-object as $_[1]
# and the values requested in Instructions.pm, in subsequent indexes like this:
# $_[0] = Checkout -object ($self/this)
# $_[1] = CheckoutsImportChain::Reader -object containing repositories and whatnot
# $_[2]->[] = Parameters extracted according to instructions in Instructions.pm

sub set_borrowernumber {
    if ($_[2]->[0]) {
		$_[0]->{borrowernumber} = $_[2]->[0];
    }
    else {
		$log->warning('Unidentifiable history has no user');
		return 'KILL MEE!';
    }
}
sub get_borrowernumber {
    return $_[0]->{borrowernumber};
}
sub set_itemnumber {
    if ($_[2]->[0]) {
		#make negative copyid's positive, as they are normalized in ItemsImportChain as well.
		if ($_[2]->[0] < 0) {
			$_[0]->{itemnumber} = -1 * $_[2]->[0];
		}
		else {
			$_[0]->{itemnumber} = $_[2]->[0];
		}
    }
    else {
		$log->warning('History with user '.$_[0]->get_borrowernumber().' has no itemnumber');
		return 'KILL MEE!';
    }
}
sub get_itemnumber {
    return $_[0]->{itemnumber};
}
sub set_biblionumber {
    if ($_[2]->[0]) {
		$_[0]->{biblionumber} = $_[2]->[0];
    }
    else {
		$log->warning('Unidentifiable history has no biblionumber');
		return 'KILL MEE!';
    }
}
sub get_biblionumber {
    return $_[0]->{biblionumber};
}
sub set_issuedate {
    if (! $_[2]->[0]) {
		$log->warning('History for userId '.$_[0]->get_borrowernumber().' and itemId '.$_[0]->get_itemnumber().' has a bad issuedate');
		return 'KILL MEE!';
    }
    $_[0]->{issuedate} = CommonRoutines::iso_standardize_date($_[2]->[0]);
}
sub get_issuedate {
    return $_[0]->{issuedate};
}
sub set_returndate {
    if (not(defined($_[2]->[0]))) { #returndate can be 0 which is completely ok. This just means that the Item has not bee returned yet.
		$log->warning('History for userId '.$_[0]->get_borrowernumber().' and itemId '.$_[0]->get_itemnumber().' has a bad returndate');
		return 'KILL MEE!';
    }
    $_[0]->{returndate} = CommonRoutines::iso_standardize_date($_[2]->[0]);
}
sub get_returndate {
    return $_[0]->{returndate};
}

####################### END OF ACCESSORS #####################
## starting behavioral methods ##

#Will destroy these MOFOs Justin Case. Should be no circular references etc, but you never know.
sub DESTROY {
    my $self = shift;
    
    foreach my $k (keys %$self) {
        
        undef $self->{$k};
        delete $self->{$k};
    }
}

sub toString {
    
    my $p = shift;
    
    my $objectString = '$VAR1 = bless( {';
    
    for my $key (sort keys %$p) {
	#print $p->{$key};
	$p->{$key} = Encode::decode_utf8($p->{$key}); # set the flag
	#print "\n";
	
	$objectString .= "'$key' => '$p->{$key}',";
    }
    $objectString =~ s/,$//; #remove last comma.
    $objectString .= "}, 'Checkout' );";
    
    #(utf8::is_utf8($objectString)) ?print "(=D)" : print "(:()";
    
    #$objectString = Encode::decode_utf8($objectString); # set the flag
    return $objectString;
}

1;
