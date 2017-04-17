package MMT::Objects::Fine;

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
    $s->borrowernumber(6); #7 AsiakasID
    $s->itemnumber(9);     #10 NideID
    $s->date(4);           #5 Luontipaiva
    $s->amount(5);         #6 Maksumaara
    $s->amountoutstanding(); # amount() ->
    $s->description(3,8,10); #4 Luontipiste + 9 VarausID + 11 Lisatiedot
    $s->accounttype(1);    #2 Tyyppi
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
        print $s->_error("No mandatory column '7 AsiakasID'");
        die "BADPARAM";
    }
    $s->{borrowernumber} = $s->{c}->[$c1];
}
sub itemnumber {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        return;
    }
    $s->{itemnumber} = $s->{c}->[$c1];
}
sub date {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        print $s->_error("No mandatory column '5 Luontipaiva'");
        die "BADPARAM";
    }
    $s->{date} = $s->{c}->[$c1];
}
sub amount {
    my ($s, $c1) = @_;
    my $amount = $s->{c}->[$c1];

    unless ($amount) {
        print $s->_error("No mandatory column '6 Maksumaara'");
        die "BADPARAM";
    }
    $s->{amount} = $amount;
}
sub amountoutstanding {
    my ($s) = @_;
    $s->{amountoutstanding} = $s->{amount};
}
sub description {
    my ($s, $c1, $c2, $c3) = @_;
    my $branchcodeId = $s->{c}->[$c1]; #4 Luontipiste
    my $reservationId = $s->{c}->[$c2]; #9 VarausID
    my $info = $s->{c}->[$c3]; #11 Lisatiedot
    my $branchcode = TranslationTables::branch_translation::translatePiste($branchcodeId);

    if ($branchcode eq 'DELETE') {
        print $s->_errorPk("'4 Luontipiste' is DELETE");
        die "BADPARAM";
    }

    my @descriptions;
    push @descriptions, 'Maksu Varauksesta' if ($reservationId);
    push @descriptions, "Kirjastosta $branchcode" if ($branchcode);
    push @descriptions, $info if $info;

    $s->{description} = join(' ][ ', @descriptions);
}
sub accounttype {
    my ($s, $c1) = @_;
    my $accounttype = $s->{c}->[$c1];

    unless (defined($accounttype)) {
        print $s->_errorPk("No mandatory column '2 Tyyppi'");
        $s->{accounttype} = 'KONVE';
        return;
    }
    $s->{accounttype} = $accounttype;
}

1;
