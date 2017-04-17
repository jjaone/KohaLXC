package TranslationTables::branch_translation;

use Modern::Perl;

our $kirkasKunnat = {
    248 => 'KIT_KES', #1 Kesälahden kunnankirjasto
    260 => 'KIT_KIT', #2 Kiteen kaupunginkirjasto
    707 => 'RAA_RAA', #3 Rääkkylän kunnankirjasto
    848 => 'TOH_TOH', #5 Tohmajärven kunnankirjasto
};

our $kirkasPisteet = {
# Origo ID => Koha branchcode, Koha location #
#---------------------------------------------
    1 => "KIT_KES", #KE Kesälahden kirjasto
    2 => "KIT_KIT", #KI Kiteen pääkirjasto
    3 => "TOH_KAU", #KA Kiteen kirjastoauto
    4 => "KIT_PUH", #KP Puhoksen kirjasto
    5 => "DELETE", #KT Terveyskeskuksen kirjasto
    6 => "RAA_RAA", #RP Rääkkylän pääkirjasto
    9 => "DELETE", #RR Rasivaaran kirjasto
    10 => "DELETE", #VK Tohmajärven kirjasto /Värtsilä
    11 => "DELETE", #AR Arppen koulu
    12 => "DELETE", #LU Kiteen lukio
    13 => "DELETE", #OP K-K:n kansalaisopisto
    14 => ["KONVERSIO","VAR"], #VA Varasto/siirtolaina -> Put to location Varasto, branch KONVERSIO
    20 => "TOH_TOH", #PK Tohmajärven pääkirjasto
    23 => "TOH_KAU", #AU Tohmajärven kirjastoauto
    27 => "TOH_KAU", #KA Kirkas-auto
};

sub translatePiste {
    my ($code) = @_;

    my $value = $kirkasPisteet->{$code} if defined($code);
    unless ($value) {
        print "Missing branch translation code '$code'\n";
        return;
    }
    if (ref($value) eq 'ARRAY') {
        return ($value->[0], $value->[1]);
    }
    return $value;
}

sub translateKunta {
    my ($code, $noWarning) = @_;

    my $value = $kirkasKunnat->{$code} if defined($code);
    if (not($value) && not($noWarning)) {
        print "Missing municipality translation code '$code'\n";
        return;
    }
    return $value;
}

1;
