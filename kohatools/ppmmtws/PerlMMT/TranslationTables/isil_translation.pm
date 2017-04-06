package TranslationTables::isil_translation;

use Modern::Perl;
use Carp qw(cluck);

#select the correct call number location according to the library id
our $isilMapJokunen = {
    1 => "FI-Jm",
    3 => "FI-Konti",
    4 => "FI-Outku",
    5 => "FI-Polvi",
    6 => "FI-Pyhas",
    8 => "FI-Juuka",
    9 => "FI-Lipri",
    10 => "FI-Eno",
};
our $isilMapPielinen = {
    1 => "FI-Nurme",
    2 => "FI-Liksa",
    3 => "FI-Iloma",
};

our $marcFieldToIsilMapJokunen = {
    "098" => "FI-Jm",
    "055" => "FI-Konti",
    "056" => "FI-Outku",
    "057" => "FI-Polvi",
    "058" => "FI-Pyhas",
    "053" => "FI-Juuka",
    "060" => "FI-Lipri",
    "064" => "FI-Eno",
};
our $marcFieldToIsilMapPielinen = {
    "098" => "DEFAULT_ISIL",
    "056" => "FI-Nurme",
    "055" => "FI-Iloma",
    "054" => "FI-Liksa",
};

sub GetIsil {
    my ($libid) = @_;

    my $isil;
    if ($CFG::CFG->{organization} eq 'pielinen') {
        $isil = $isilMapPielinen->{$libid};
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        $isil = $isilMapJokunen->{$libid};
    }
    else {
        cluck "No such organization '$CFG::CFG->{organization}' mapped!";
    }
    if ($isil) {
        return $isil;
    }
    else {
        cluck "No such library id '$libid' mapped!";
        return "";
    }
}
sub GetDefaultIsil {
    if ($CFG::CFG->{organization} eq 'pielinen') {
        return 'DEFAULT_ISIL'; #In pielinen, the default ISIL is not owned by anyone.
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        return GetIsil(1); #In jokunen, the field 098 had the default isil and it was the same as Joensuu's call number.
    }
}

sub GetField2Isil {
    my ($marcField) = @_;

    my $isil;
    if ($CFG::CFG->{organization} eq 'pielinen') {
        $isil = $marcFieldToIsilMapPielinen->{$marcField};
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        $isil = $marcFieldToIsilMapJokunen->{$marcField};
    }
    else {
        cluck "No such organization '$CFG::CFG->{organization}' mapped!";
    }
    if ($isil) {
        return $isil;
    }
    else {
        return undef;
    }
}