package TranslationTables::departmentCode_translation;

use Modern::Perl;

# kotipiste => kotiosasto => department code #
#--------------------------------------------#
our $departmentCodeKirkas = {
1 => {         #KE Kesälahden kirjasto
    1 => "KEA",   #A Aikuisten osasto
    2 => "KEK",   #K Käsikirjasto
    3 => "KEKO",  #Ko Kotiseutukokoelma
    4 => "KEL",   #L Lasten osasto
    5 => "KEN",   #N Nuorten osasto
    6 => "KENA",  #NA Nuorten aikuisten osasto
    13 => "",     #NK Nuorten käsikirjasto
    8 => "KEVA",  #VA Varasto
    9 => "KEVL",  #VL Lasten varasto
    10 => "KEVN", #VN Nuorten varasto
    11 => "",     #LE Lehtiosasto
    12 => "KEKH", #KH Kirjaston henkilökunta
    14 => "KEO",  #O Oheislukemisto
    16 => "",     #VK Käsikirjasto, varasto
    7 => "",      #S Siirtolaina
    15 => "",     #V Varasto
},
2 => {         #KI Kiteen pääkirjasto
    1 => "KIA",   #A Aikuisten osasto
    2 => "KIK",   #K Käsikirjasto
    3 => "KIKO",  #Ko Kotiseutukokoelma
    4 => "KIL",   #L Lasten osasto
    5 => "KIN",   #N Nuorten osasto
    6 => "KINA",  #NA Nuorten aikuisten osasto
    13 => "KINK", #NK Nuorten käsikirjasto
    8 => "KIVA",  #VA Varasto
    9 => "KIVL",  #VL Lasten varasto
    10 => "KIVN", #VN Nuorten varasto
    11 => "KILE", #LE Lehtiosasto
    12 => "KIKH", #KH Kirjaston henkilökunta
    14 => "KIO",  #O Oheislukemisto
    16 => "KIVK", #VK Käsikirjasto, varasto
    7 => "KIS",   #S Siirtolaina
    15 => "KIV",  #V Varasto
    25 => "",     #VL Varasto, lasten ja nuorten kir  :(
},
3 => "",       #KA Kirkas-auto

4 => {         #KP Puhoksen kirjasto
    1 => "KPA",   #A Aikuisten osasto
    2 => "KPK",   #K Käsikirjasto
    3 => "",      #Ko Kotiseutukokoelma
    4 => "KPL",   #L Lasten osasto
    5 => "KPN",   #N Nuorten osasto
    6 => "KPNA",  #NA Nuorten aikuisten osasto
    13 => "KPNK", #NK Nuorten käsikirjasto
    8 => "",      #VA Varasto
    9 => "",      #VL Lasten varasto
    10 => "",     #VN Nuorten varasto
    11 => "KPLE", #LE Lehtiosasto
    12 => "KPKH", #KH Kirjaston henkilökunta
    14 => "",     #O Oheislukemisto
    16 => "",     #VK Käsikirjasto, varasto
    7 => "",      #S Siirtolaina
    15 => "",     #V Varasto
},
6 => {         #RP Rääkkylän pääkirjasto
    1 => "RPA",   #A Aikuisten osasto
    2 => "RPK",   #K Käsikirjasto
    3 => "RPKO",  #KO Kotiseutukokoelma
    4 => "RPL",   #L Lasten osasto
    5 => "RPN",   #N Nuorten osasto
    11 => "RPLE", #LE Lehtiosasto
    12 => "RPKH", #KH Kirjaston henkilökunta
    15 => "RPV",  #V Varasto
    18 => "RPL",  #KU Kuvakirjaosasto
    19 => "RPOL", #OL Oheislukemistot
    25 => "RPVL", #VL Varasto, lasten ja nuorten kir
},
20 => {      #PK Tohmajärven pääkirjasto
    1 => "PKA",   #A Aikuisten osasto
    2 => "PKK",   #K Käsikirjasto
    3 => "PKKO",  #Ko Kotiseutukokoelma
    4 => "PKL",   #L Lasten osasto
    5 => "PKN",   #N Nuorten osasto
    6 => "PKNA",  #NA Nuorten aikuisten osasto        :(
    7 => "PKS",   #S Siirtolaina                      :(
    8 => "PKV",   #VA Varasto                         :(
    10 => "PKNV", #VN Nuorten varasto
    11 => "PKLE", #LE Lehtiosasto
    12 => "PKKH", #KH Kirjaston henkilökunta          :(
    14 => "PKO",  #O Oheislukemisto
    15 => "PKV",  #V Varasto                          :(
    25 => "PKLV", #VL Varasto, lasten ja nuorten kir  :(
    30 => "PKM",  #M Musiikkiosasto
    31 => "PKV",  #A:V Aikuisten varasto => Varasto
    32 => "PKLE", #SA Lehtiosasto aikakau             :(
    39 => "PKLE", #KP Kotipalvelu                     :(
},
};

=head
@RETURNS String, -undef means the value has not been mapped but mappings have been given.
                 -empty string "" means the value has been mapped and is deliberately empty.
                 -other values are the department codes.
=cut
sub fetch {
    my ($branchId, $departmentId) = @_;
    my $branchLevel = $departmentCodeKirkas->{$branchId};
    if ($branchLevel) {
        return $branchLevel->{$departmentId};
    }
    return "";
}

1;
