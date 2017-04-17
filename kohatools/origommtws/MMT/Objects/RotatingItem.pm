package MMT::Objects::RotatingItem;

use Modern::Perl;

use MMT::Util::Common;
use TranslationTables::branch_translation;

use MMT::Objects::BaseObject;
use base qw(MMT::Objects::BaseObject);

=head1 SYNOPSIS

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
    $s->itemnumber(1);       #2 NideID
    $s->transfer_branch(2);  #3 Siirtopiste
    $s->origin_branch(3);    #4 Lainauspiste
    $s->date_added(4);       #5 LainausAika
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

sub itemnumber {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        print $s->_error("No mandatory column '2 NideID'");
        die "BADPARAM";
    }
    $s->{itemnumber} = $s->{c}->[$c1];
}
sub transfer_branch {
    my ($s, $c1) = @_;
    my $transferBranchId = $s->{c}->[$c1];

    unless (defined($transferBranchId)) {
        print $s->_error("Missing column '3 Siirtopiste'");
        return;
    }

    my $transferBranch = TranslationTables::branch_translation::translatePiste($transferBranchId);
    if ($transferBranch eq 'DELETE') {
        print $s->_errorPk("'3 Siirtopiste' is DELETE");
        die "BADPARAM";
    }

    if (!$transferBranch) {
        $s->{transfer_branch} = 'KONVERSIO';
    }
    else {
        $s->{transfer_branch} = $transferBranch;
    }
}
sub origin_branch {
    my ($s, $c1) = @_;
    my $originBranchId = $s->{c}->[$c1];

    unless (defined($originBranchId)) {
        print $s->_error("Missing column '4 Lainauspiste'");
        return;
    }

    my $originBranch = TranslationTables::branch_translation::translatePiste($originBranchId);
    if ($originBranch eq 'DELETE') {
        print $s->_errorPk("'4 Lainauspiste' is DELETE");
        die "BADPARAM";
    }

    if (!$originBranch) {
        $s->{origin_branch} = 'KONVERSIO';
    }
    else {
        $s->{origin_branch} = $originBranch;
    }
}
sub date_added {
    my ($s, $c1) = @_;

    unless (defined($s->{c}->[$c1])) {
        print $s->_error("Missing column '5 LainausAika'");
    }
    $s->{date_added} = $s->{c}->[$c1];
}

1;
