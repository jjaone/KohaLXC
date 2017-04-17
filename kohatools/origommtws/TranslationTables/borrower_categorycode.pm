package TranslationTables::borrower_categorycode;

use Modern::Perl;
use Carp qw(cluck);

our $tableJokunen = {
    '0' => 'HENKILO',
    '1' => 'YHTEISO',
    '2' => 'TAKAAJA',
    '3' => 'KIRJASTO',
    '4' => 'KAUKOLAINA',
    '5' => 'KOTIPALVEL',
    '6' => 'LAPSI',
    '8' => 'KAUKOLAINA',
    '9' => 'TILASTO',
};

our $tablePielinen = {
    '0' => 'HENKILO',
    '1' => 'YHTEISO',
    '2' => 'VIRKAILIJA',
    '3' => 'KIRJASTO',
    '4' => 'KOTIPALVEL',
    '6' => 'LAPSI', #OK
    '9' => 'TILASTO', #OK
};

our $tableKirkas = {
    0 => 'HENKILO', #Not defined in the Origo dump, but user reports state that these are legit 'HENKILO'.
    1 => 'HENKILO', #henkilö
    2 => 'TAKAAJA', #takaaja
    3 => 'KAUKOLAINA', #muun kunnan kirjasto
    4 => 'YHTEISO', #muu hallintokunta
    5 => 'YHTEISO', #muu julkisyhteisö
    6 => 'YHTEISO', #yksityinen yritys tms
    7 => 'KIRJASTO', #oma kirjastolaitos (sekal.)
    8 => 'KIRJASTO', #oma kirjastol. (p-piste + os.)
    9 => 'KONVERSIO', #tilapäinen sijoituspaikka
};

sub fetch {
    my ($key) = @_;
    my $borcat;

    if ($CFG::CFG->{organization} eq 'kirkas') {
        $borcat = $tableKirkas->{$key} if exists $tableKirkas->{$key};
    }
    elsif ($CFG::CFG->{organization} eq 'pielinen') {
        $borcat = $tablePielinen->{$key} if exists $tablePielinen->{$key};
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        $borcat = $tableJokunen->{$key} if exists $tableJokunen->{$key};
    }
    else {
        cluck "No such organization '$CFG::CFG->{organization}' mapped!";
    }
    return $borcat if $borcat;
    print "Missing borrower category translation code '$key'\n";
    return;
}