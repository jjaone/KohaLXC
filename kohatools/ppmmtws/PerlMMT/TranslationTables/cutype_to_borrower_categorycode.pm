#This translation table is not used anywhere. It is here just for trying out better organization.

package TranslationTables::cutype_to_borrower_categorycode;

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

sub fetch {
    my $key = shift();
    my $borcat;

    if ($CFG::CFG->{organization} eq 'pielinen') {
        $borcat = $tablePielinen->{$key} if exists $tablePielinen->{$key};
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        $borcat = $tableJokunen->{$key} if exists $tableJokunen->{$key};
    }
    else {
        cluck "No such organization '$CFG::CFG->{organization}' mapped!";
    }
    return $borcat if $borcat;
    return undef;
}