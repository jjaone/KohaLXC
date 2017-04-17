package MMT::Objects::Checkout;

use Modern::Perl;

use Encode;

use MMT::Util::Common;
use TranslationTables::branch_translation;

use MMT::Objects::BaseObject;
use base qw(MMT::Objects::BaseObject);

=head1 SYNOPSIS
Container for item fields. Accessors use validators to make sure data is valid.

@PARAM1 ARRAYRef, The .csv-row parsed to columns
=cut
sub constructor {
    my ($class, $controller, $columns) = @_;
    my $s = {};
    bless($s, $class);
    $s->{controller} = $controller; #Create a temporary reference to the controller containing all the repositories
    $s->{c} = $columns;

    eval {
    ##Column mapping rules
    $s->borrowernumber(1); #2 AsiakasID
    $s->itemnumber(2);     #3 NideID
    $s->issuedate(4);      #5 LainausAika
    $s->date_due(5);       #6 Erapaiva
    $s->branchcode(3);     #4 Lainauspiste -> AuktPiste.txt
    $s->renewals(11);      #12 Uusimiskerta - 0-10
    };
    if ($@) {
        if ($@ =~ /BADPARAM/) {
            return undef;
        }
        else {
            print $@;
        }
    }

    delete $s->{controller}; #remove the excess references.
    delete $s->{c};
    return $s;
}

sub borrowernumber {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        print $s->_error("No mandatory column '2 AsiakasID'");
        die "BADPARAM";
    }
    $s->{borrowernumber} = $s->{c}->[$c1];
}
sub itemnumber {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        print $s->_error("No mandatory column '3 NideID'");
        die "BADPARAM";
    }
    $s->{itemnumber} = $s->{c}->[$c1];
}
sub issuedate {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        print $s->_error("No mandatory column '5 LainausAika'");
        die "BADPARAM";
    }
    $s->{issuedate} = $s->{c}->[$c1];
}
sub date_due {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        print $s->_error("No mandatory column '6 Erapaiva'");
        die "BADPARAM";
    }
    $s->{date_due} = $s->{c}->[$c1];
}
sub branchcode {
    my ($s, $c1) = @_;
    my $branchcode = $s->{c}->[$c1];

    unless ($branchcode) {
        print $s->_error("No mandatory column '4 Lainauspiste'");
        die "BADPARAM";
    }

    $branchcode = TranslationTables::branch_translation::translatePiste($branchcode);
    if ($branchcode eq 'DELETE') {
        print $s->_errorPk("'4 Lainauspiste' is DELETE");
        die "BADPARAM";
    }

    if (!$branchcode) {
        $s->{branchcode} = 'KONVERSIO';
    }
    else {
        $s->{branchcode} = $branchcode;
    }
}
sub renewals {
    my ($s, $c1) = @_;
    my $renewals = $s->{c}->[$c1];

    unless (defined($renewals)) {
        print $s->_error("Missing column '12 Uusimiskerta'");
    }

    $s->{renewals} = $renewals;
}

1;
