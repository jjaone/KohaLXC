package TranslationTables::SourceValidationRules;

use Modern::Perl;

my $svr = {

"_config" => {
    quote =>  '"',
    separator => "\t",
    line_terminator => "\n",
    xml_max_length => 750, #A safety mechanism to prevent the XML parser from slurping the whole file if bad XML is encountered.
},

"AuktAlennusprosentti.txt" => [
#    'int',                            #1 ID
#    'EI TARVITA',
],

"AuktAsiakastyyppi.txt" => [ # -> koha.categories
    {parser => 'int', type => 'int'},                                                                  #1 ID
    {parser => 'xml', type => 'string', postproc => 'grep <tekstit><fin><pitkanimi>(.*?)</pitkanimi>'} #2 Kuvaus
],

"AuktHankintatapa.txt" => [
    {parser => 'int', type => 'int'},                                                         #1 ID
    [   {parser => 'xml', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #2 Koodi
        {parser => 'xml', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #2 Kuvaus
    ],
],

"AuktHylly.txt" => [
    {parser => 'int', type => 'int'},                                                                       #1 ID
    [   {parser => 'xml', type => 'string', postproc => 'grep <tekstit><fin><lyhytnimi>(.*?)</lyhytnimi>'}, #2 Koodi
        {parser => 'xml', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'},               #2 Nimi
    ],
],

"AuktKayttaja.txt" => [ # -> Jotain geneerisiä käyttötunnuksia? Ilmeisesti automaatti ja virkailijatunnuksia.
    {parser => 'int', type => 'int'},                                                         #1 ID
    [   {parser => 'xml', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #2 Koodi
        {parser => 'xml', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #2 Nimi
    ],
],

"AuktKieli.txt" => [
    {parser => 'int', type => 'int'},       #1 ID
    {parser => 'string', type => 'string'}, #2 Kieliasut - ei tarvita
    {parser => 'string', type => 'string'}, #3 Kielikoodi
],

"AuktKirjasto.txt" => [ # -> Isot katto-organisaatiot?
    {parser => 'int', type => 'int'},                                                         #1 ID
    [   {parser => 'xml', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #2 Koodi
        {parser => 'xml', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #2 Nimi
    ],
    {parser => 'string', type => 'string'}, #3 Luokkakentta
    {parser => 'string', type => 'string'}, #4 LaskunumeronAlaraja
    {parser => 'string', type => 'string'}, #5 LaskunumeronYlaraja
    {parser => 'string', type => 'string'}, #6 Verkkomaksaminen
    {parser => 'string', type => 'string'}, #7 Mobiilimaksaminen
    {parser => 'string', type => 'string'}, #8 BudjettikaudenAlku
    {parser => 'string', type => 'string'}, #9 BudjetointiSaapumispaivanMukaan
    {parser => 'string', type => 'string'}, #10 LaajennettuHankinta
],

"AuktKuntajoukko.txt" => [
#    'TYHJÄ'
],

"AuktLainaAika.txt" => [ # -> koha."circulation rules" Käytettävä näitä konversiossa jos aktiivisille lainoille ei eräpäivää ole muutoin määritelty
    {parser => 'int', type => 'int'},                                                         #1 ID
    {parser => 'xml', type => 'int', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #1 Päiviä
],

"AuktLainamaararajoitus.txt" => [
#    'TYHJÄ'
],

"AuktLuokka.txt" => [
    {parser => 'int', type => 'int'},                                                            #1 ID
    [   {parser => 'string', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #1 Luokka
        {parser => 'string', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #1 Kuvaus
    ],
    {parser => 'double', type => 'double'},                                                      #2 Luokka, käytä saraketta 1 
    {parser => 'int', type => 'int'},                                                            #3 PaaluokkaID - viittaa sarakkeeseen "0 ID" - ei tarvita
],

"AuktMaksumaaritys.txt" => [
#    'EI TARVITA''
],

"AuktMateriaali.txt" => [ # -> koha.itemtypes
    {parser => 'int', type => 'int'},                                                         #1 ID
    [   {parser => 'xml', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #1 Aineistolaji
        {parser => 'xml', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #1 Kuvaus
    ],
],

"AuktNiteentila.txt" => [ # -> koha.authorized_values
    {parser => 'int', type => 'int'},                                                         #1 ID
    [   {parser => 'xml', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #1 Status
        {parser => 'xml', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #1 Kuvaus
    ],
],

"AuktOsasto.txt" => [ # -> koha.shelving_location
    {parser => 'int', type => 'int'},                                                         #1 ID
    [   {parser => 'xml', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #1 Koodi
        {parser => 'xml', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #1 Nimi
    ],
],

"AuktPiste.txt" => [ # -> koha.branches
    {parser => 'int', type => 'int'},                                                         #1 ID
    [   {parser => 'string', type => 'string', postproc => 'grep <lyhytnimi>(.*?)</lyhytnimi>'}, #1 Koodi
        {parser => 'string', type => 'string', postproc => 'grep <pitkanimi>(.*?)</pitkanimi>'}, #1 Nimi
    ],
],

"AuktPisteryhma.txt" => [
#    'EI TARVITA'
],

"AuktPisteryhmaJasenet.txt" => [
#    'EI TARVITA'
],

"AuktPysakki.txt" => [
#    'EI TARVITA'
#    'int', # ID
#    {'xml' => 'grep <tekstit><fin><lyhytnimi>(.*?)</lyhytnimi>'}, # Nimi
],

"Asiakas.txt" => [ # -> koha.borrowers
    {parser => 'string', type => 'key'},    #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'int', type => 'int'},       #2 Kotikunta - 260
    {parser => 'string', type => 'datetime'},#3 VoimassaAlku
    {parser => 'string', type => 'datetime'},#4 VoimassaLoppu
    {parser => 'string', type => 'boolean'},#5 VoimassaToistuva - (False|True)
    {parser => 'string', type => 'string'}, #6 Aidinkieli (suomi|ruotsi|Venäjä)
    {parser => 'string', type => 'string'}, #7 Huomautus
    {parser => 'string', type => 'string'}, #8 Kayttokieli (fin|)
    {parser => 'string', type => 'boolean'},#9 HenkilollisyysTarkistettava (False|True)
    {parser => 'int', type => 'int'},       #10 Saapumisilmoitustapa - [1234]
    {parser => 'int', type => 'int'},       #11 Huomautuskirjetapa - [12]
    {parser => 'string', type => 'datetime'},#12 LisaysPvm - 2005-04-27 11:11:04.403
    {parser => 'string', type => 'datetime'},#13 TallennusPvm - 2005-04-27 11:11:04.403
    {parser => 'int', type => 'int'},       #14 Lisaaja - \d+
    {parser => 'int', type => 'int'},       #15 Tallentaja - \d+
    {parser => 'int', type => 'int'},       #16 Asiakastyyppi - \d+
    {parser => 'string', type => 'key'},    #17 TakaajaID
    {parser => 'string', type => 'boolean'},#18 TakaajaPoistetaan (False|True)
    {parser => 'string', type => 'string'}, #19 Sukunimi Aapro-Malinen
    {parser => 'string', type => 'string'}, #20 Etunimet Tiuku Kaste-Helmi
    {parser => 'string', type => 'string'}, #21 Kutsumanimi Petri
    {parser => 'string', type => 'datetime', postproc => 'grep ^(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)'},#22 Syntymaaika
    {parser => 'string', type => 'string'}, #23 Tunnus/Sotu
    {parser => 'int', type => 'int'},       #24 Sukupuoli - \d+
    {parser => 'string', type => 'string'}, #25 Kansalaisuus - (Romania|Suomen|Venäjä|Venäjän|Ruotsi)
    {parser => 'string', type => 'string'}, #26 Sahkoposti
    {parser => 'string', type => 'string'}, #27 Url
    {parser => 'string', type => 'string'}, #28 Lisatiedot
    {parser => 'string', type => 'key'},    #29 KontaktiID
    {parser => 'string', type => 'string'}, #30 Salakala
],

"Asiakasviivakoodi.txt" => [ # -> Asiakas.txt
    {parser => 'string', type => 'string'}, #1 Viivakoodi
    {parser => 'string', type => 'key'},    #2 AsiakasID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'int', type => 'int'},       #3 Jarjestys
    {parser => 'string', type => 'string'}, #4 ViivakoodiNimi
],

"Hankinta.txt" => [ # -> koha.items
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 TeosID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #3 ToimittajaID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'int', type => 'int'},         #4 Piste
    {parser => 'int', type => 'int'},         #5 Kotiosasto
    {parser => 'string', type => 'double'},   #6 Hinta
    {parser => 'int', type => 'int'},         #7 Lukumaara
    {parser => 'int', type => 'int'},         #8 ALVprosentti
    {parser => 'string', type => 'double'},   #9 AlennusProsentti
    {parser => 'string', type => 'datetime'}, #10 Tilausaika - 2005-04-27 11:11:04.403
    {parser => 'string', type => 'datetime'}, #11 Syottoaika - 2005-04-27 11:11:04.403
    {parser => 'string', type => 'boolean'},  #12 Tilattu (False|True)
    {parser => 'string', type => 'string'},   #13 Lisatiedot
    {parser => 'string', type => 'datetime'}, #14 TallennusPvm - 2005-04-27 11:11:04.403
    {parser => 'int', type => 'int'},         #15 Lisaaja
    {parser => 'int', type => 'int'},         #16 Tallentaja
    {parser => 'string', type => 'boolean'},  #17 TilataanSidonta. Oi sido minut!
],

"Laina.txt" => [ # -> koha.issues
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 AsiakasID
    {parser => 'string', type => 'key'},      #3 NideID
    {parser => 'int', type => 'int'},         #4 Lainauspiste - 2 -> AuktPiste.txt
    {parser => 'string', type => 'datetime'}, #5 LainausAika
    {parser => 'string', type => 'datetime'}, #6 Erapaiva
    {parser => 'int', type => 'int'},         #7 Pysakki - 115
    {parser => 'int', type => 'int'},         #8 Huomautusluokka - [01234]
    {parser => 'string', type => 'datetime'}, #9 HuomautusAika
    {parser => 'string', type => 'boolean'},  #10 EiHuomauteta (False|True)
    {parser => 'int', type => 'int'},         #11 Tekotapa, luonnollinen - [01247]
    {parser => 'int', type => 'int'},         #12 Uusimiskerta - 0-10
],

"Lainauskielto.txt" => [ # -> koha.borrower_debarments
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 AsiakasID
    {parser => 'string', type => 'datetime'}, #3 Paivamaara
    {parser => 'string', type => 'string'},   #4 Syy
    {parser => 'string', type => 'boolean'},  #5 Lainauskielto (False|True)
],

"Liiteaineisto.txt" => [
#    'EI TARVITA'
],

"Maksu.txt" => [ # -> koha.fines
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'int', type => 'int'},         #2 Tyyppi - 1,2,3,4,5,99
    {parser => 'int', type => 'int'},         #3 Huomautusluokka - [1234]
    {parser => 'int', type => 'int'},         #4 Luontipiste - \d+
    {parser => 'string', type => 'datetime'}, #5 Luontipaiva
    {parser => 'string', type => 'double'},   #6 Maksumaara
    {parser => 'string', type => 'key'},      #7 AsiakasID
    {parser => 'string', type => 'key'},      #8 LainaID
    {parser => 'string', type => 'key'},      #9 VarausID
    {parser => 'string', type => 'key'},      #9 NideID
    {parser => 'string', type => 'string'},   #10 Lisatiedot
],

"Nide.txt" => [ # -> koha.items
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'string'},   #2 Viivakoodi
    {parser => 'string', type => 'key'},      #3 TeosID
    {parser => 'string', type => 'key'},      #4 ToimittajaID
    {parser => 'int', type => 'int'},         #5 Kotipiste
    {parser => 'int', type => 'int'},         #6 Piste
    {parser => 'int', type => 'int'},         #7 Kotiosasto
    {parser => 'int', type => 'int'},         #8 Osasto
    {parser => 'int', type => 'int'},         #9 Hylly
    {parser => 'int', type => 'int'},         #10 Hankintatapa
    {parser => 'int', type => 'int'},         #11 Tila - 0,1,2,3,4,5,6,8,9,11
    {parser => 'int', type => 'int'},         #12 LainaAika - 0,1,2,3,4,19,27
    {parser => 'int', type => 'int'},         #13 TilapLainaAika - 0,1,2,3,4,20,30
    {parser => 'int', type => 'int'},         #14 TilapHylly - 0
    {parser => 'string', type => 'datetime'}, #15 TilapLainaAikaAlku
    {parser => 'string', type => 'datetime'}, #16 TilapLainaAikaLoppu
    {parser => 'string', type => 'string'},   #17 Luokka
    {parser => 'string', type => 'boolean'},  #18 Lainauskielto
    {parser => 'int', type => 'int'},         #19 Tulostus - 0,3,4,...,44,54
    {parser => 'string', type => 'datetime'}, #20 HankintaPvm
    {parser => 'string', type => 'datetime'}, #21 UutuusPvm
    {parser => 'string', type => 'string'},   #22 HankintaNumero - Lahjoitus/Varis, undef
    {parser => 'string', type => 'double'},   #23 Hankintahinta
    {parser => 'string', type => 'double'},   #24 Korvaushinta
    {parser => 'string', type => 'double'},   #25 Alennusprosentti
    {parser => 'string', type => 'double'},   #26 ALVprosentti
    {parser => 'string', type => 'string'},   #27 LainausHuomautus
    {parser => 'string', type => 'string'},   #28 PalautusHuomautus
    {parser => 'string', type => 'string'},   #29 Lisatiedot
    {parser => 'string', type => 'datetime'}, #30 MuutosPvm
    {parser => 'int', type => 'int'},         #31 Kuljetuksessa - [01]
    {parser => 'string', type => 'boolean'},  #32 Uusimiskielto
    {parser => 'string', type => 'boolean'},  #33 Varauskielto
    {parser => 'string', type => 'datetime'}, #34 LisaysPvm
    {parser => 'string', type => 'datetime'}, #35 TallennusPvm
    {parser => 'string', type => 'datetime'}, #36 HavaintoPvm
    {parser => 'int', type => 'int'},         #37 Lisaaja
    {parser => 'int', type => 'int'},         #38 Tallentaja
    {parser => 'string', type => 'boolean'},  #39 Viimeistelyssa
    {parser => 'string', type => 'boolean'},  #40 Kadonnut
    {parser => 'int', type => 'int'},         #41 Havaintotapa
    {parser => 'string', type => 'boolean'},  #42 Uutuusluetteloon
    {parser => 'string', type => 'string'},   #43 UID - ei dataa
    {parser => 'int', type => 'int'},         #44 Paino - 0
    {parser => 'int', type => 'int'},         #45 Pituus - 0
    {parser => 'int', type => 'int'},         #46 Leveys - 0
    {parser => 'int', type => 'int'},         #47 Paksuus - 0
    {parser => 'int', type => 'int'},         #48 LkmLainaVVVV - 0-24
    {parser => 'int', type => 'int'},         #49 LkmLainaYht - 0-389
],

"Osoite.txt" => [ # -> Asiakas.txt
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 KontaktiID
    {parser => 'string', type => 'string'},   #3 Katuosoite
    {parser => 'string', type => 'string'},   #4 Lisarivi - ei dataa
    {parser => 'string', type => 'string'},   #5 Maa - suooni, suoni, N.S.W. Australia
    {parser => 'string', type => 'string'},   #6 Postinumero
    {parser => 'string', type => 'string'},   #7 Postitoimipaikka
    {parser => 'string', type => 'datetime'}, #8 VoimassaAlku
    {parser => 'string', type => 'datetime'}, #9 VoimassaLoppu
    {parser => 'string', type => 'boolean'},  #10 VoimassaToistuva (False|True)
    {parser => 'int', type => 'int'},         #11 Jarjestys - [0123]
],

"Puhelin.txt" => [ # -> Asiakas.txt
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 KontaktiID
    {parser => 'string', type => 'string'},   #3 Numero - 5.481058, 450432345, 013 - 665 454, Soita varatusta aineistosta
    {parser => 'int', type => 'int'},         #4 Tyyppi - [0123456]
    {parser => 'string', type => 'boolean'},  #5 Tekstiviestit
],

"Siirtolaina.txt" => [ # -> koha.?
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 NideID
    {parser => 'int', type => 'int'},         #3 Siirtopiste - 1,2,3,4,5,9,27
    {parser => 'int', type => 'int'},         #4 Lainauspiste - 1,2,3,4,6,10,20,27
    {parser => 'string', type => 'datetime'}, #5 LainausAika
    {parser => 'string', type => 'datetime'}, #6 Erapaiva
],

"Teos.txt" => [ # -> koha.?
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'int', type => 'int'},         #2 Materiaali- 1,3,5,10,100001
    {parser => 'string', type => 'datetime'}, #3 MuutosPvm
    {parser => 'int', type => 'int'},         #4 Tilauksessa - [01]
    {parser => 'string', type => 'string'},   #5 Tilaustunnus - ISBN, tai muu teksti
    {parser => 'string', type => 'datetime'}, #6 LisaysPvm
    {parser => 'string', type => 'datetime'}, #7 TallennusPvm
    {parser => 'int', type => 'int'},         #8 Lisaaja - 1,2,3,...,47,54
    {parser => 'int', type => 'int'},         #9 Tallentaja - 1,2,3,...,47,54
    {parser => 'int', type => 'int'},         #10 Luettelointikesken - [01]
],

"Toimittaja.txt" => [ # -> koha.?
#    'EI TARVITA',
],

"Varaus.txt" => [ # -> koha.reserves
    {parser => 'string', type => 'key'},      #1 ID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 AsiakasID
    {parser => 'string', type => 'key'},      #3 NideID
    {parser => 'int', type => 'int'},         #4 Varauspiste - 1,2,6,20,27
    {parser => 'int', type => 'int'},         #5 Kiinniottopiste
    {parser => 'int', type => 'int'},         #6 Noutopiste
    {parser => 'string', type => 'datetime'}, #7 Luontipaiva
    {parser => 'string', type => 'datetime'}, #8 Saapumispaiva
    {parser => 'string', type => 'datetime'}, #9 Viimeinenpaiva
    {parser => 'string', type => 'datetime'}, #10 Ilmoituspaiva
    {parser => 'int', type => 'int'},         #11 Ilmoitustapa - [0136]
    {parser => 'string', type => 'datetime'}, #12 ViimeinenNoutopaiva
    {parser => 'string', type => 'datetime'}, #13 Alkamispaiva
    {parser => 'int', type => 'int'},         #14 Tekotapa - [14]
    {parser => 'int', type => 'int'},         #15 Saapunut - [01]
    {parser => 'int', type => 'int'},         #16 KelluvaNoutopiste - [01]
    {parser => 'string', type => 'string'},   #17 Lisatiedot - ei dataa
],

"Varausrivi.txt" => [ # -> Varaus.txt
    {parser => 'string', type => 'key'},      #1 VarausID - #0401077E-0104-11D2-B24C-00104B5471B8
    {parser => 'string', type => 'key'},      #2 TeosID
    {parser => 'string', type => 'key'},      #3 NideID
    {parser => 'int', type => 'int'},         #4 Jarjestys - 1,3,5,...,107,149
],

};










################################################################################
################################################################################
######################                                    ######################
##################          STARTING WITH ACCESSORS           ##################
######################                                    ######################
################################################################################
################################################################################

sub get {
    return $svr;
}

sub getParser {
    my ($filename, $column) = @_;

    my $rule = _getRuleOrDie($filename, $column, 1);
    return $rule->{parser};
}

sub getRules {
    my ($filename, $column) = @_;

    my $rules = _getRuleOrDie($filename, $column);
    return $rules;
}

sub getRuleColumns {
    my ($filename) = @_;

    my $rule = _getRuleOrDie($filename);
    if (ref($rule) eq 'ARRAY') {
        return scalar(@$rule);
    }
    else {
        die "Tables::SourceValidationRules::getRuleColumns($filename):> \$filename's '$filename' rule is not an ARRAY!";
    }
}

sub _getRuleOrDie {
    my ($filename, $column, $single) = @_;
    my $rule = $svr->{$filename};

    unless (ref($rule) eq 'ARRAY') {
        die "Tables::SourceValidationRules::_getRuleOrDie():> No source validation rule, for file '$filename'.\n";
    }

    if (defined($column)) {
        $rule = $rule->[$column];
        unless ($rule) {
            die "Tables::SourceValidationRules::_getRuleOrDie():> No source validation rule column, for file '$filename' and column '$column'.\n";
        }
    }

    if ($single && ref($rule) eq 'ARRAY') {
        return $rule->[0];
    }
    return $rule;
}

1;
