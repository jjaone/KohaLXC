package MMT::Objects::Hold;

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
    $s->borrowernumber(1);       #2 AsiakasID
    $s->biblionumber(0);         #1 ID -> Varausrivi
    $s->itemnumber(2);           #3 NideID
    $s->branchcode(5);           #6 Noutopiste
    $s->waitingdate(7);          #8 Saapumispaiva -> found = 'W'
    $s->priority(0);             #1 ID -> Varausrivi
    $s->reservedate(6);          #7 Luontipaiva
    $s->expirationdate(8);       #9 Viimeinenpaiva
    $s->suspend_until(12);       #13 Alkamispaiva
    $s->reservenotes(16);        #17 Lisatiedot
    $s->{constrainttype} = 'a';  #Always 'a' in Koha
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
sub biblionumber {
    my ($s, $c1) = @_;
    my $reservationID = $s->{c}->[$c1];

    unless ($reservationID) {
        print $s->_error("No mandatory column '1 ID'");
        die "BADPARAM";
    }

    my $reservationRow = $s->{controller}->{repositories}->{Varausrivi}->fetch( $reservationID );
    unless ($reservationRow) {
        print $s->_error("No authority 'Varausrivi'.");
        die "BADPARAM";
    }

    if (ref($reservationRow) eq 'ARRAY' && ref($reservationRow->[0]) eq 'ARRAY') {
        $reservationRow = $reservationRow->[0];
        print $s->_errorPk("Unexpected multirow authority 'Varausrivi', recovering from error.");
    }

    my $biblionumber = $reservationRow->[1]; #TeosID
    unless ($biblionumber) {
        print $s->_error("No TeosID in authority 'Varausrivi'.");
        die "BADPARAM";
    }
    $s->{biblionumber} = $biblionumber;
}
sub itemnumber {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        return;
    }
    $s->{itemnumber} = $s->{c}->[$c1];
}
sub branchcode {
    my ($s, $c1) = @_;
    my $branchcodeID = $s->{c}->[$c1];

    unless ($branchcodeID) {
        print $s->_error("No mandatory column '6 Noutopiste'");
        die "BADPARAM";
    }

    my $branchcode = TranslationTables::branch_translation::translatePiste($branchcodeID);
    if ($branchcode eq 'DELETE') {
        print $s->_errorPk("'6 Noutopiste' is DELETE");
        die "BADPARAM";
    }

    if (!$branchcode) {
        $s->{branchcode} = 'KONVERSIO';
    }
    else {
        $s->{branchcode} = $branchcode;
    }
}
sub waitingdate {
    my ($s, $c1) = @_;
    my $arrivalDate = $s->_KohalizeDate($s->{c}->[$c1]);

    unless ($arrivalDate) {
        return;
    }

    $s->{waitingdate} = $arrivalDate;
    $s->{found} = 'W';
}
sub priority {
    my ($s, $c1) = @_;
    my $reservationID = $s->{c}->[$c1];

    unless ($reservationID) {
        print $s->_error("No mandatory column '1 ID'");
        die "BADPARAM";
    }

    my $reservationRow = $s->{controller}->{repositories}->{Varausrivi}->fetch( $reservationID );
    die "BADPARAM" unless $reservationRow; #If missing, error is already thrown in biblionumber()

    if (ref($reservationRow) eq 'ARRAY' && ref($reservationRow->[0]) eq 'ARRAY') {
        $reservationRow = $reservationRow->[0];
    }

    my $priority = $reservationRow->[3]; #Jarjestys
    unless ($priority) {
        print $s->_error("No Jarjestys in authority 'Varausrivi'.");
        die "BADPARAM";
    }

    #In Koha a found priority is 0, in Origo it is 1.
    if ($s->{found}) {
        if ($priority != 1) {
            print $s->_errorPk("Holds is found but priority is not 0.");
        }
        $priority = "0";
    }
    $s->{priority} = $priority;
}
sub reservedate {
    my ($s, $c1) = @_;
    my $createDate = $s->_KohalizeDate($s->{c}->[$c1]);

    unless ($createDate) {
        print $s->_error("Mandatory column '7 Luontipaiva' is invalid");
        die "BADPARAM";
    }

    $s->{reservedate} = $createDate;
}
sub expirationdate {
    my ($s, $c1) = @_;
    my $expirationdate = $s->_KohalizeDate($s->{c}->[$c1]);

    unless ($expirationdate) {
        return;
    }

    $s->{expirationdate} = $expirationdate;
}
sub suspend_until {
    my ($s, $c1) = @_;
    my $suspend_until = $s->_KohalizeDate($s->{c}->[$c1]);

    unless ($suspend_until) {
        return;
    }

    if (substr($s->{reservedate},0,10) ne substr($suspend_until,0,10)) {
        $s->{suspend_until} = $suspend_until;
        $s->{suspend} = 1;
    }
}
sub reservenotes {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        return;
    }
    $s->{reservenotes} = $s->{c}->[$c1];
}

1;
