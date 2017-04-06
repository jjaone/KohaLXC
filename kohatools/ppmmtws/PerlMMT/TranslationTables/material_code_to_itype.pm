#This translation table is not used anywhere. It is here just for trying out better organization.

package TranslationTables::material_code_to_itype;

use Modern::Perl;
use Carp qw(cluck);

#Noticed that all ä are replaced with | in licmarca.kir
#Second value indicates whether or not this material code is a serial and should be imported as such?
our $tableJokunen = {
    'al' => ['AL', 1], #We need isASerial to separate serials from items
    '|t' => ['ÄT'],
    'br' => ['BR'],
    'cd' => ['CD'],
    'cr' => ['CR'],
    'di' => ['DI'],
    'dr' => ['DR'],
    'dv' => ['DV'],
    'es' => ['ES'],
    'ka' => ['KA'],
    'ki' => ['KI'],
    'k|' => ['KÄ'],
    'ko' => ['KO'],
    'kp' => ['KP'],
    'kr' => ['KR'],
    'ku' => ['KU'],
    'le' => ['LE'],
    'mf' => ['MF'],
    'mk' => ['MK'],
    'mm' => ['MM'],
    'mo' => ['MO'],
    'mp' => ['MP'],
    'n|' => ['NÄ'],
    'nu' => ['NU'],
    'pa' => ['PA'],
    'sk' => ['SK'],
    'sl' => ['SL', 1], #We need isASerial to separate serials from items
    'ty' => ['TY'],
    'va' => ['VA'],
    'vi' => ['VI'],
};

our $tablePielinen = {
    'la' => ['AL', 1], #Aikakauslehti(lain.) => Aikakauslehti
    'at' => ['MM'], #Atk-tallenne? => Muu mikrotallenne, OK Poistavat.
    'br' => ['BR'], #Blu-ray
    'cd' => ['CD'], #CD-äänilevy
    'cr' => ['CR'], #CD-ROM
    'c|' => ['CD'], #CD-Äänilevy
    'di' => ['DI'], #Dia
    'dv' => ['DV'], #DVD-Video
    'el' => ['VA'], #Elektroninen lehti? => Verkkoaineisto, ei olemassa. Poistavat.
    'es' => ['ES'], #Esine
    'kr' => ['KR'], #Kartta
    'ka' => ['KA'], #C-kasetti
    'kk' => ['ÄT'], #Kielikurssi? => Ääni ja teksti. OK.
    'ki' => ['KI'], #Kirja
    'ku' => ['KU'], #Kuunnelma? . Hävittävät. Muutetaan oikeaksi ääniformaatiksi (cd, kasetti, lp, ...)
    'kv' => ['KU'], #Kuva
    'k|' => ['KK'], #käsikirjoitus(alkup.) => Käsikirjoitus
    'kj' => ['KK'], #käsikirjoitus(jälj.) => Käsikirjoitus
    'le' => ['LK'], #Leikekansio? => uusi(Leikekansio)
    'lp' => ['LE'], #Äänilevy
    'mf' => ['MF'], #Mikrofilmi
    'mk' => ['MK'], #Mikrokortti
    'mv' => ['MO'], #Moniviestin
    'mp' => ['MP'], #MP3
    'mm' => ['MM'], #MuuMikrotuote? => Muu mikrotallenne. OK, Tarkistavat onko olemassa.
    'm|' => ['MO'], #MuuÄänite? => Moniviestin. Muuttavat aineiston C-kasetiksi.
    'nu' => ['NU'], #Nuotti
    'n|' => ['NÄ'], #Nuotti + Äänite
    'on' => ['KI'], #Opinnäyte? => Kirja. OK, tarkastavat vielä.
    'pa' => ['PA'], #Partituuri
    'pp' => ['KI'], #Pienpainate? => Kirja, OK. Tarkastavat ovatko lehtiä.
    'sl' => ['SL', 1], #Sanomalehti
    'si' => ['LE'], #Single? => Moniviestin. OK hävitetään.
    'so' => ['SK'], #Sokeainkirjoitus.
    'sk' => ['VA'], #Sähköinen kirja? => Verkkoaineisto. OK
    'ty' => ['TY'], #Työpiirrustus
    've' => ['VA'], #Verkkoaineisto
    'vv' => ['VI'], #Video(VHS)
    'vl' => ['MO'], #Videolevy? => Moniviestin, OK ei yhtään olemassa.
    '|k' => ['KA'], #Äänikirja? Muutetaan kasetiksi, itse muuttavat muut formaatit oikein.
    'CA' => ['CA'], #Celia Äänikirja. Is set in MARC::Record->materialType(). This is just a passthrough.
    'KP' => ['KP'], #Console game passthrough.
};

sub fetch {
    my $key = shift();
    $key =~ s/ä/|/; #make sure ä is | as some sources use 'ät' and some sources use '|t'
    my $itype;

    if ($CFG::CFG->{organization} eq 'pielinen') {
        $itype = $tablePielinen->{$key} if exists $tablePielinen->{$key};
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        $itype = $tableJokunen->{$key} if exists $tableJokunen->{$key};
    }
    else {
        cluck "No such organization '$CFG::CFG->{organization}' mapped!";
    }
    return $itype if $itype;
    return undef;
}