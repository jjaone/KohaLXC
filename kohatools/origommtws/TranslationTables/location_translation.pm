package TranslationTables::location_translation;

use Modern::Perl;

our $kirkas = {
    1 => "AIK", #A Aikuisten osasto
    2 => "REF", #K Käsikirjasto
    3 => "KOT", #KO Kotiseutukokoelma
    4 => "LAP", #L Lasten osasto
    5 => "NUO", #N Nuorten osasto
    6 => "NUA", #NA Nuortenaikuisten osasto
    7 => "SII", #S Siirtolaina
    8 => "VAR", #VA Varasto
    9 => "LVA", #VL Lasten varasto
    10 => "NUV", #VN Nuorten varasto
    11 => "LEH", #LE Lehtiosasto
    12 => "HEN", #KH Kirjaston henkilökunta
    13 => "LAK", #NK Nuorten käsikirjasto
    14 => "OHE", #O Oheislukemisto
    15 => "VAR", #V Varasto
    16 => "VAR", #VK Käsikirjasto, varasto
    17 => "VAR", #VX Varasto, leikekokoelma
    18 => "KUV", #KU Kuvakirjaosasto
    19 => "OHE", #OL Oheislukemistot
    20 => "SII", #SA Siirtolaina:aikuiset
    21 => "SII", #SL Siirtolaina:lapset
    22 => "KONVERSIO", #K Kirjasto
    23 => "KONVERSIO", #N Koulukirjasto
    24 => "VAR", #S Varasto/siirtolaina
    25 => "LVA", #VL Varasto, lasten ja nuorten kir
    30 => "MUS", #M Musiikkiosasto
    31 => "VAR", #VAR A:V Aikuiset, varasto
    32 => "LEH", #SA Lehtiosasto, aikakau
    33 => "LEH", #SS Lehtiosasto, sanomal
    34 => "KONVERSIO", #L L
    35 => "KONVERSIO", #V V
    39 => "Kotipalvelu", #KP Kotipalvelu
};

=head
Get the permanent_location
=cut
sub location {
    my ($code) = @_;
    if (defined($code)) {
        my $a = $kirkas->{$code};

        unless ($a) {
            print "Missing location translation code '$code'\n";
            return;
        }

        return $a;
    }
}

1;
