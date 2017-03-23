package Checkout;

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

sub set_status {
    my $status1 = $_[2]->[0];
    my $status2 = $_[2]->[1];
    $_[0]->{status} = $status1.'|'.$status2;
    
    #if lilloan->status2 has negative values, those CheckOuts are never used anywhere, so we remove them.
    if (   $status2 == -2 || $status2 == -1   ) {
		return 'KILL MEE!';
    }
	
	if ($status1 >= 100) {
		#100 or 101 = CheckOut is in transit and has been returned
		#120 = returned today
		return "KILL MEE!"; #Don't migrate such foolishness
	}
}
sub get_status {
    return $_[0]->{status};
}
sub set_borrowernumber {
    if ($_[2]->[0]) {
		$_[0]->{borrowernumber} = $_[2]->[0];
    }
    else {
		$log->warning('Unidentifiable checkout has no user');
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
		$log->warning('Checkout with user '.$_[0]->get_borrowernumber().' has no itemnumber');
		return 'KILL MEE!';
    }
}
sub get_itemnumber {
    return $_[0]->{itemnumber};
}
sub set_branchcode {
    my $licloqde = TranslationTables::liqlocde_translation::resolve(  { locid => $_[2]->[0], depid => $_[2]->[1] }  );
    my $branchcode = $licloqde->[1];
	my $shelvingLocation = $licloqde->[2];

    if (! $branchcode) {
        $log->warning('Checkout for user '.$_[0]->get_borrowernumber().' in locid => '.$_[2]->[0].', depid => '.$_[2]->[1].' has a undefined circulation library');
		return 'KILL MEE!';
    }
	if ($shelvingLocation eq 'POIS') {
		return 'KILL MEE!';
	}

    $_[0]->{branchcode} = $branchcode;
}
sub get_branchcode {
    return $_[0]->{branchcode};
}
sub set_circ_staff {
    $_[0]->{circ_staff} = $_[2]->[0];
}
sub get_circ_staff {
    return $_[0]->{circ_staff};
}
#PP marks renewals using the status1-column. It starts with 1, and increments for each renew.
#status1 has values of 100 and 120, but lets omit them for now.
sub set_renewals {
    my $status1 = $_[2]->[0];
    
    if (! $status1) {
		$log->warning('Checkout for userId '.$_[0]->get_borrowernumber().' and itemId '.$_[0]->get_itemnumber().' has a bad status1');
		return 'KILL MEE!';
    }
	else {
		$_[0]->{renewals} = ($status1 - 1);
	}
}
sub get_renewals {
    return $_[0]->{renewals};
}
sub set_grace_period {
    $_[0]->{grace_period} = $_[2]->[0];
}
sub get_grace_period {
    return $_[0]->{grace_period};
}

sub set_date_due {
    if (! $_[2]->[0]) {
		$log->warning('Checkout for userId '.$_[0]->get_borrowernumber().' and itemId '.$_[0]->get_itemnumber().' has a bad date_due');
		return 'KILL MEE!';
    }
    $_[0]->{date_due} = CommonRoutines::iso_standardize_date($_[2]->[0]);
}
sub get_date_due {
    return $_[0]->{date_due};
}

sub set_issuedate {
    if (! $_[2]->[0]) {
		$log->warning('Checkout for userId '.$_[0]->get_borrowernumber().' and itemId '.$_[0]->get_itemnumber().' has a bad issuedate');
		return 'KILL MEE!';
    }
    $_[0]->{issuedate} = CommonRoutines::iso_standardize_date($_[2]->[0]);
}
sub get_issuedate {
    return $_[0]->{issuedate};
}


sub set_create_time {
    if (! $_[2]->[0]) {
		$log->warning('Checkout for userId '.$_[0]->get_borrowernumber().' and itemId '.$_[0]->get_itemnumber().' has a bad create_time');
		return 'KILL MEE!';
    }
    else {
        $_[0]->{create_time} = CommonRoutines::iso_standardize_date($_[2]->[0]);
    }
}
sub get_create_time {
    return $_[0]->{create_time};
}
sub set_duration {
    #used values are already checked for existence in set_date_due and set_create_date
    my $duration = CommonRoutines::subtract_dates( $_[2]->[0] , $_[2]->[1] , 'i');
    
    $_[0]->{duration} = $duration;
}
sub get_duration {
    return $_[0]->{duration};
}
#if this loan is created in a pikalaina-department, then it has a higher fine
#WARNING is coupled with duration_rule, recurring_fine_rule:
#  they check if recurring_fine >= 0.50, to decide if this is a pikalaina or not
sub set_recurring_fine {
    my $licloqde = TranslationTables::liqlocde_translation::resolve(  { locid => $_[2]->[0], depid => $_[2]->[1] }  );
    my $oldLocName = $licloqde->[0];

    if ( $oldLocName =~ m/PIKA/) {
	$_[0]->{recurring_fine} = '0.50';
    }
    else {
	$_[0]->{recurring_fine} = '0.20';
    }
}
sub get_recurring_fine {
    return $_[0]->{recurring_fine};
}
sub set_max_fine {
    $_[0]->{max_fine} = $_[2]->[0];
}
sub get_max_fine {
    return $_[0]->{max_fine};
}
sub set_duration_rule {
    my $pikalaina = ($_[0]->{recurring_fine} >= 0.50) ? 't' : 'f';
	
    $_[0]->{duration_rule} = ($pikalaina eq 't') ? '7_days_0_renew' : $_[2]->[0];
}
sub get_duration_rule {
    return $_[0]->{duration_rule};
}
sub set_recurring_fine_rule {
    my $pikalaina = ($_[0]->{recurring_fine} >= 0.50) ? 't' : 'f';
	
    $_[0]->{recurring_fine_rule} = ($pikalaina eq 't') ? '7_days_0_renew' : $_[2]->[0];
}
sub get_recurring_fine_rule {
    return $_[0]->{duration_rule};
}
sub set_max_fine_rule {	
    $_[0]->{max_fine_rule} = $_[2]->[0];
}
sub get_max_fine_rule {
    return $_[0]->{max_fine_rule};
}
sub set_workstation {	
    $_[0]->{workstation} = $_[2]->[0];
}
sub get_workstation {
    return $_[0]->{workstation};
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
