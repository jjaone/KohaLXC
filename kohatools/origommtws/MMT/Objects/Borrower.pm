package MMT::Objects::Borrower;

use Modern::Perl;

use Encode;
use DateTime;
use DateTime::Format::ISO8601;

use MMT::Util::Common;
use TranslationTables::branch_translation;
use TranslationTables::borrower_categorycode;
use MMT::Borrowers::SsnToSsnStore;

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
    $s->borrowernumber(0);   #1 ID
    $s->cardnumber();        # borrowernumber -> Asiakasviivakoodi.csv
    $s->surname(18);         #19 Sukunimi
    $s->firstname(19);       #20 Etunimet
    $s->othernames();        #surname + firstname + random
    $s->addresses(28);       #29 KontaktiID -> Osoite.csv
    $s->email(25);           #26 Sahkoposti
    $s->phonesAndMobiles(28);#29 KontaktiID -> Puhelin.csv
    $s->dateofbirth(21);     #22 Syntymaaika
    $s->branchcode(1);       #cardnumber() or 2 Kotikunta
    $s->dateenrolled(11,12); #12 LisaysPvm, 13 TallennusPvm
    $s->dateexpiry(3);       #4 VoimassaLoppu
    $s->guarantorid(16);     #17 TakaajaID
    $s->categorycode(15);    #16 Asiakastyyppi -> AuktAsiakastyyppi.csv
    $s->sex(23);             #24 Sukupuoli
    $s->password(29);        #30 Salakala
    $s->userid(22);          #23 Tunnus/Sotu
    $s->opacnote(6);         #7 Huomautus
    $s->contactnote(6);      #7 Huomautus
    $s->standing_penalties();# borrowernumber -> Lainauskielto.csv
    $s->{privacy} = 1;
    $s->{ssn} = MMT::Borrowers::SsnToSsnStore::appendValues($s->{ssn}) if $s->{ssn}; #Store the confirmed SSN to repository
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
        print $s->_error("No mandatory column '1 ID'");
        die "BADPARAM";
    }
    $s->{borrowernumber} = $s->{c}->[$c1];
}
my $badCardnumberCounter = 1;
sub cardnumber {
    my ($s) = @_;

    my $badBarcodeError = sub {
        my $errorStr = shift;
        $s->{cardnumber} = "KONVERSIO$badCardnumberCounter";
        $badCardnumberCounter++;
        print $s->_errorPk($errorStr);
        return;
    };

    my $isGuarantor = $s->{controller}->{repositories}->{TakaajaID}->fetch($s->{borrowernumber});
    my $barcodes = $s->{controller}->{repositories}->{Asiakasviivakoodi}->fetch($s->{borrowernumber});

    if (not($barcodes) && not($isGuarantor)) {
        return &$badBarcodeError("Missing cardnumber authority record");
    }
    elsif (not($barcodes) && $isGuarantor) {
        $s->{categorycode} = 'TAKAAJA';
        return;
    }

#if ($s->{borrowernumber} eq '0400DE35-0104-11D2-B24C-00104B5471B8') {
#    print "Breakpoint";
#}

    $barcodes = [$barcodes] unless ref($barcodes) eq 'ARRAY';
    $barcodes = [$barcodes] unless ref($barcodes->[0]) eq 'ARRAY';
    ##Find the top priority card. While doing that look for SSNs
    my ($topPriority, $topPriorityIndex, $ssn) = (9999,0,''); #Top priority is 0
    for (my $i=0 ; $i<scalar(@$barcodes); $i++) {
        my $bc = $barcodes->[$i];

        if ($s->_findSSN($bc)) { #If we find a SSN, drop it, adust the array index and keep searching.
            splice(@$barcodes, $i, 1);
            $i--;
            next();
        }

        if ($bc->[2] < $topPriority) { #Priority column
            $topPriority = $bc->[2];
            $topPriorityIndex = $i;
        }
    }

    my $barcode = $barcodes->[$topPriorityIndex];
    return &$badBarcodeError("No valid barcode") unless ($barcode);

    $s->{cardnumber} = $barcode->[0];
}
sub surname {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        #print $s->_error("Missing column '$c1'");
        return;
    }
    $s->{surname} = $s->{c}->[$c1];
}
sub firstname {
    my ($s, $c1) = @_;

    unless ($s->{c}->[$c1]) {
        #print $s->_error("Missing column '$c1'");
        return;
    }
    $s->{firstname} = $s->{c}->[$c1];
}
sub othernames {
    my ($s) = @_;
    my $sn = $s->{surname} || '';
    my $fn = $s->{firstname} || '';
    $s->{othernames} = $sn.','.$fn.int(rand(10000));
}
sub addresses {
    my ($s, $c1) = @_;
    unless ($s->{c}->[$c1]) {
        print $s->_error("Missing column '$c1'");
        return;
    }

    my $osoites = $s->{controller}->{repositories}->{Osoite}->fetch( $s->{c}->[$c1] );
    return unless ($osoites);
    $osoites = [$osoites] unless ref($osoites) eq 'ARRAY';
    $osoites = [$osoites] unless ref($osoites->[0]) eq 'ARRAY';

    ##Sort addresses by order-column.
    my @addressByOrder;
    foreach my $addr (@$osoites) {
        @addressByOrder[$addr->[10]] = $addr; #Order is column 11
    }

    #Add addresses, lowest order number comes first.
    for(my $i=0; $i<scalar(@addressByOrder) ; $i++) {
        my $addr = $addressByOrder[$i];
        unless ($addr) { #Deal with possible undef order indexes.
            splice(@addressByOrder, $i, 1);
            $i--;
            next;
        }
        my $a = {
            address => $addr->[2], #3 Katuosoite
            country => $addr->[3], #4 Maa
            zipcode => $addr->[5], #6 Postinumero
            city    => $addr->[6], #7 Postitoimipaikka
        };
        if ($i == 0) {
            $s->{address} = $a->{address};
            $s->{country} = $a->{country};
            $s->{zipcode} = $a->{zipcode};
            $s->{city}    = $a->{city};
        }
        elsif ($i == 1) {
            $s->{B_address} = $a->{address};
            $s->{B_country} = $a->{country};
            $s->{B_zipcode} = $a->{zipcode};
            $s->{B_city}    = $a->{city};
        }
        elsif ($i == 2) {
            $s->{altcontactaddress1} = $a->{address};
            $s->{altcontactcountry}  = $a->{country};
            $s->{altcontactzipcode}  = $a->{zipcode};
            $s->{altcontactaddress3} = $a->{city};
        }
        elsif ($i > 2) {
            #We can only support 3 alternate addresses.
        }
    }
}
sub email {
    my ($s, $c1) = @_;
    unless ($s->{c}->[$c1]) {
        #print $s->_error("Missing column '$c1'");
        return;
    }

    $s->{email} = $s->{c}->[$c1];
}
my $smsValidatorMonster = qr/(((90[0-9]{3})?0|\+358([-\s])?)(?!(100|20(0|2(0|[2-3])|9[8-9])|300|600|700|708|75(00[0-3]|(1|2)\d{2}|30[0-2]|32[0-2]|75[0-2]|98[0-2])))(4|50|10[1-9]|20(1|2(1|[4-9])|[3-9])|29|30[1-9]|71|73|75(00[3-9]|30[3-9]|32[3-9]|53[3-9]|83[3-9])|2|3|5|6|8|9|1[3-9])([-\s])?(\d{1,3}[-\s]?){2,12}\d)/;
sub phonesAndMobiles {
    my ($s, $c1) = @_;
    my $contactID = $s->{c}->[$c1];
    unless ($contactID) {
        print $s->_error("Missing column '$c1'");
        return;
    }

    my $puhelins = $s->{controller}->{repositories}->{Puhelin}->fetch( $contactID );
    return unless ($puhelins);
    $puhelins = [$puhelins] unless ref($puhelins) eq 'ARRAY';
    $puhelins = [$puhelins] unless ref($puhelins->[0]) eq 'ARRAY';

    #Add phones in the order they gave been introduced since there is no clear way of ordering them
    for(my $i=0; $i<scalar(@$puhelins) ; $i++) {
        my $pho = $puhelins->[$i];
        unless ($pho) { #Deal with possible undef order indexes.
            next;
        }
        my $number = $pho->[2]; #3 Numero
        my $type = $pho->[3];   #4 Tyyppi
        my $smsOk = ($pho->[4] && $pho->[4] =~ /true/i) ? 1 : 0;   #5 Tekstiviestit, translate boolean

        unless ($number) {
            print $s->_errorNoDump("Borrower ID '".$s->{borrowernumber}."', ContactID '$contactID', Undefined number");
            next();
        }

        #Add phones by type
        if ($type == 0) {
            $s->{phone} = $number;
        }
        elsif ($type == 1) {
            $s->{altcontactphone} = $number;
        }
        elsif ($type == 2) {
            if ($smsOk) {
                if ($number =~ /$smsValidatorMonster/) {
                    $s->{smsalertnumber} = $1;
                }
                else {
                    print $s->_errorNoDump("Borrower ID '".$s->{borrowernumber}."', ContactID '$contactID', Bad smsalertnumber '".$number."'");
                }
            }
            $s->{mobile} = $number;
        }
        elsif ($type > 2) {
            print $s->_errorNoDump("Borrower ID '".$s->{borrowernumber}."', ContactID '$contactID' unknown phone type '$type'");
            $s->{phonepro} = $number;
        }
    }
}
sub dateofbirth {
    my ($s, $c1) = @_;

    unless (defined($s->{c}->[$c1])) {
        print $s->_error("Missing column '22 Syntymaaika'");
        return;
    }
    $s->{dateofbirth} = $s->{c}->[$c1];
}
sub branchcode {
    my ($s, $c1) = @_;
    my $municipalityCode = $s->{c}->[$c1];

    #Try defaulting to the first three numbers in the borrower's cardnumber.
    if ($s->{cardnumber} && $s->{cardnumber} =~ /^(\d{3})/) {
        my $municipalityCodeFromBarcode = $1;
        if (my $homebranch = TranslationTables::branch_translation::translateKunta($municipalityCodeFromBarcode, 'noWarning')) {
            $s->{branchcode} = $homebranch;
            return 1;
        }
    }

    unless (defined($s->{c}->[$c1])) {
        print $s->_error("Missing column '2 Kotikunta'");
        return;
    }

    if ($municipalityCode =~ /^\d+$/) {
        my $homebranch = TranslationTables::branch_translation::translateKunta($municipalityCode);
        $s->{branchcode} = $homebranch || 'KONVERSIO';
    }
    else {
        $s->_addNote("Virheellinen maakuntakoodi '$municipalityCode'");
        print $s->_errorNoDump("ID '".$s->{borrowernumber}."'. Bad municipality code '$municipalityCode'");
        $s->{branchcode} = 'KONVERSIO';
    }
}
my $childAgeThreshold = DateTime->now()->subtract(years => 16)->ymd('');
sub categorycode {
    my ($s, $c1) = @_;
    my $borrowerCategory = $s->{c}->[$c1];

    unless (defined($borrowerCategory)) {
        print $s->_errorPk("Missing column '16 Asiakastyyppi'");
        return;
    }
    if ($s->{categorycode}) { #Categorycode already defined in cardnumber
        return;
    }

    my $categorycode = TranslationTables::borrower_categorycode::fetch($borrowerCategory);
    unless ($categorycode) {
        $categorycode = 'HENKILO';
        $s->_addNote("Virheellinen asiakaslaji '$borrowerCategory'");
        print $s->_errorPk("Bad Borrower category '$borrowerCategory'");
    }

    if ($s->{guarantorid} && $categorycode eq 'HENKILO') { #HENKILO which has a guarantor, is either a child or a guarantee.
        my $dob = $s->{dateofbirth};
        $dob =~ s/\D//g; #Drop digits so we can easily compare
        $dob = substr($dob,0,8); #Normalize, we could also use DateTime but that would be much slower.
        if ($dob > $childAgeThreshold) {
            $categorycode = 'LAPSI';
        }
        else {
            $categorycode = 'MUUKUINLAP';
        }
    }

    $s->{categorycode} = $categorycode;
}
sub dateenrolled {
    my ($s, $c1, $c2) = @_;
    my $dateAdded = $s->{c}->[$c1];
    my $dateModified = $s->{c}->[$c2];

    my $date = $s->_KohalizeDate($dateAdded);
    unless ($date) {
        $date = $s->_KohalizeDate($dateModified);
    }

    $s->{dateenrolled} = $date if $date;
}
sub dateexpiry {
    my ($s, $c1) = @_;
    my $dateExpiry = $s->{c}->[$c1];

    unless (defined($dateExpiry)) {
        print $s->_error("Missing column '4 VoimassaLoppu'");
        return;
    }

    if ($dateExpiry =~ /^1900/) { #If the value is 1900-01-01, we give it the default expiration date.
        $dateExpiry = DateTime->now();
        $dateExpiry->add( days => 720+int(rand(360)) );
        $dateExpiry = $dateExpiry->ymd('-') . ' ' . $dateExpiry->hms(':')
    }
    $s->{dateexpiry} = $dateExpiry;
}
sub guarantorid {
    my ($s, $c1) = @_;

    #unless (defined($s->{c}->[$c1])) {
        #print $s->_error("Missing column '17 TakaajaID'");
    #}
    my $guarantorId = $s->{c}->[$c1];
    if ($guarantorId) {
        #Convert TakaajaID via KontaktiID to AsiakasID for some reason?
        my $kontaktiIdAry = $s->{controller}->{repositories}->{KontaktiID_to_AsiakasID}->fetch( $guarantorId );
        if ($kontaktiIdAry) {
            $s->{guarantorid} = $kontaktiIdAry->[0];
        }
        else {
            print $s->_errorPk("Column '17 TakaajaID' present, but no guarantor found.");
        }
    }
}
sub sex {
    my ($s, $c1) = @_;
    my $sex = $s->{c}->[$c1]; #1 == male, 2 == female

    unless (defined($sex)) {
        print $s->_error("Missing column '24 Sukupuoli'");
        return;
    }

    $sex = _sexChange($sex); #Transform integer to character

    if ($s->{sex} && $s->{sex} ne $sex) {
        print $s->_errorNoDump("Borrower ID '".$s->{borrowernumber}."'. Sex exchange! Sex '".$s->{sex}."' already given from SSN, but changed to '$sex'");
    }
    $s->{sex} = $sex;
}
sub password {
    my ($s, $c1) = @_;
    my $password = $s->{c}->[$c1];

    unless (defined($password)) {
        print $s->_error("Missing column '30 Salakala'");
        return;
    }

    if (length($password) < 5) {
        #print $s->_errorNoDump("Borrower ID '".$s->{borrowernumber}."'. Password is less than 4 characters. Password invalidated.");
        $password = rand(9999999999)+1000;
        $s->_addNote("Liian heikko salasana poistettu");
    }

    $s->{password} = $password;
}
sub userid {
    my ($s, $c1) = @_;
    my $tunnus = $s->{c}->[$c1];
    if (not($tunnus)) {
        print $s->_errorNoDump("Borrower ID '".$s->{borrowernumber}."'. Missing column '23 Tunnus/Sotu'");
        $tunnus = rand(9999999999)+1000;
    }
    elsif ($s->_findSSN($tunnus)) {
        $tunnus = rand(9999999999)+1000;
        $s->_addNote("Sotu käyttäjätunnuksena on poistettu");
        #print $s->_errorNoDump("Borrower ID '".$s->{borrowernumber}."'. SSN as username invalidated.");
    }
    $s->{userid} = $tunnus;
}
sub opacnote {
    my ($s, $c1) = @_;

    $s->{opacnote} = $s->{c}->[$c1];
}
sub contactnote {
    my ($s, $c1) = @_;

    if ($s->{contactnote}) {
        $s->{contactnote} .= $s->{c}->[$c1];
    }
    else {
        $s->{contactnote} = $s->{c}->[$c1];
    }
}
sub standing_penalties {
    my ($s) = @_;

    my $debarments = $s->{controller}->{repositories}->{Lainauskielto}->fetch( $s->{borrowernumber} );
    return unless ($debarments);
    $debarments = [$debarments] unless ref($debarments) eq 'ARRAY';
    $debarments = [$debarments] unless ref($debarments->[0]) eq 'ARRAY';

    $s->{standing_penalties} = '';
    for(my $i=0; $i<scalar(@$debarments) ; $i++) {
        my $deb = $debarments->[$i];
        my $date = $deb->[2];
        my $reason = $deb->[3];
        my $debarment = $deb->[4]; #Debarment or note? 'true if debarment
        if ($debarment eq 'true') {
            $s->{standing_penalties} .= "<99>$date<>$reason";
        }
        elsif ($reason =~ /^ok/i) { #Ok, oK, OK!, ok., ok!, Ok!, Ok., ... #This means that they have checked the borrowers contact info.
            $s->{_contactOk} = $reason; #Tag the Borrower Justin Case.
        }
        else {
            $date = substr($date,0,8);
            $s->_addNote("Lainauskieltohuomautus: $date, $reason");
        }
    }
}
sub _findSSN {
    my ($s, $string) = @_;

    ## Figure out the elusive SSN and have some sex ##
    my ($ssn, $sex) = (undef, 'Please');
    if ($string =~ /(\d{6}.\d{3}.)/) {
        $ssn = $1;
    }
    else {
        return;
    }

    ## Get sex from ssn!
    if ($ssn =~ /\d{6}.\d{2}(\d)./) {
        if ($1 % 2 == 1) {
            $sex = 'M';
        }
        else {
            $sex = 'F';
        }
    }

    #We found a new ssn and that doesn't match with the existing ssn?! This Borrowers has multiple ssns?
    if ($ssn && $s->{ssn} && $ssn ne $s->{ssn}) {
        print $s->_error("Multiple different SSN's!");
        my ($package, $filename, $line, $subroutine) = caller(1);
        if ($subroutine =~ /userid/) {
            $s->{ssn} = $ssn;
            $s->{sex} = $sex;
        }
    }
    elsif ($ssn && not($s->{ssn})) {
        $s->{ssn} = $ssn;
        $s->{sex} = $sex;
    }
    return 1; #We found a ssn.
}

sub _sexChange {
    my ($integer) = @_;
    return 'M' if $integer eq '1';
    return 'F' if $integer eq '2';
    return '';
}
1;
