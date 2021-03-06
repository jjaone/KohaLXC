package Patron;

use warnings;
use strict;
#use diagnostics;
use utf8;

use POSIX;
use Switch;

use PatronsImportChain::SsnToSsnStore;
use TranslationTables::cutype_to_borrower_categorycode;
use CommonRoutines;
use LiteLogger;

my $log;
my $censor = 1;
sub initPackageVariables {
    $log = LiteLogger->new({package => 'Patron'});
    $censor = $CFG::CFG->{PatronsImportChain}->{Censor};
}

=head1 SYNOPSIS
Container for item fields. Accessors use validators to make sure data is valid.
Fields must correspond to Instructions.pm
=cut
sub new {
    my $class = shift;
    my $s = {};

    bless($s, $class);
    return $s;
}
sub newFromRow {
    my $class = shift;
    no strict 'vars';
    eval shift;
    my $s = $VAR1;
    use strict 'vars';
    warn $@ if $@;
    return $s;

}

#setters receive self as $_[0]
# the ItemsInjectChain::Reader-object as $_[1]
# and the values requested in Instructions.pm, in subsequent indexes like this:
# $_[0] = Item -object ($self/this)
# $_[1] = ItemsImportChain::ItemsBuilder::Reader -object containing repositories and whatnot
# $_[2]->[] = Parameters extracted according to instructions in Instructions.pm

#####FOR actor.usr

sub set_active {
    my $status1 = $_[2]->[0];
    my $status2 = $_[2]->[1];
    my @byte1 = CommonRoutines::breakIntegerToBinaryArray($status1);
    my @byte2 = CommonRoutines::breakIntegerToBinaryArray($status2);
    my $active = 't'; #patron is active by default
    #1st bit = not-in-use -bit!
    $active = 'f' if $byte1[-1];
    #8th bit = annulled/mitätöity
    #$active = 'f' if $byte1[-8];
    #8th bit = inactive -bit!
    $active = 'f' if $byte2[-8];
    #check status1() for more details
    
    $_[0]->{active} = $active;
    
    return 'KILL MEE!' if $_[0]->{active} eq 'f';
}
sub get_active {
    return $_[0]->{active};
}

sub set_borrowernumber {
    if (defined $_[2]->[0]) {
        $_[0]->{borrowernumber} = $_[2]->[0];
    }
    else {
        return 'KILL MEE!';
    }
}
sub get_borrowernumber {
    return $_[0]->{borrowernumber};
}

sub set_categorycode {
    my $p = $_[0];
    my $cutype = $_[2]->[0];
    my $borCat = TranslationTables::cutype_to_borrower_categorycode::fetch($cutype);
    if ($borCat) {  $p->{categorycode} = $borCat;  }
    else {
        $p->{categorycode} = 'TILASTO';
        $_[0]->separateItemAsVolatile("set_categorycode(): Patron borrowernumber ".$_[0]->{borrowernumber}." has undefined categorycode!", 1);
    }
}
sub get_categorycode {
    return shift->{categorycode};
}

#new userid variant using barcode as the username
sub set_userid {
    $_[0]->{userid} = buildABarcode(@_);
}
sub get_userid {
    return $_[0]->{userid};
}

sub set_email {
    
    if ($_[0]->{borrowernumber} == '1104659') {
        my $break;
    }
    
    my $liwcusetEmail = $_[1]->{liwcuset}->fetchWithoutWarning(  $_[0]->{borrowernumber} , undef, 'email'  );
    my $email1 = $_[2]->[0];
    my $email2 = $_[2]->[1];
        
    if (! $liwcusetEmail) { #if we didn't get any email from liwcuset.kir
        
        if ( $email1 =~ /([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)/ ) { #censorable
            $_[0]->{email} = ($censor) ? 'sensuroitu@example.com'  :  $1.'@'.$2;
        }
        elsif ( $email2 =~ /([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)/ ) { #censorable
            $_[0]->{email} = ($censor) ? 'sensuroitu@example.com'  :  $1.'@'.$2;
        }
        else {
            $_[0]->{email} = '';
        }
    }
    else {
        $_[0]->{email} = ($censor) ? 'sensuroitu@example.com'  :  $liwcusetEmail;
    }
    print '';
}
sub get_email {
    return $_[0]->{email};
}
#sub set_emailpro {
#    my $emailpro = $_[0]->{email};
#    if (! $emailpro) {
#		return;
#    }
#    else {
#		$_[0]->{emailpro} = $emailpro;
#    }    
#}
#sub get_emailpro {
#    return $_[0]->{emailpro};
#}

sub set_password {
    if ($censor) {
        $_[0]->{password} = "1234";
    }
    else {
        my $passwd = $_[2]->[0];
        if (! ( $passwd)) {
            $passwd = "HulAbaLooBalaiBalai-HulabaL00B4l41!";
        }
        else {
            $passwd = sprintf "%04d", $passwd;
        }
        $_[0]->{password} = $passwd;
    }
}
sub get_password {
    return $_[0]->{password};
}

sub set_firstname {
    if ( $_[2]->[0] ) {
        my $fn = $_[2]->[0];
        $_[0]->{firstname} = CommonRoutines::name_normalize(  $fn  );
    }
    else {
        $_[0]->{firstname} = 'NO FIRSTNAME!';
    }
}
sub get_firstname {
    return $_[0]->{firstname};
}

sub set_surname {
    if ( $_[2]->[0] ) {
    $_[0]->{surname} = CommonRoutines::name_normalize(  $_[2]->[0]  );
    }
    else {
    $_[0]->{surname} = 'NO SURNAME!';
    }
    
    #some patrons are marked as deleted by branding their surname with "pOiStEtTu", remove these Patrons
    if ($_[0]->{surname} =~ /pOiStEtTu/i) {
    return 'KILL MEE!';
    }
    
}
sub get_surname {
    return $_[0]->{surname};
}

sub set_phone {
    my $phone = $_[2]->[0];

    if (! $phone) {
        $_[0]->{phone} = '';
        return;
    }	

    if ($censor) {
        $_[0]->{phone} = "+35813000".substr($phone, -3);
    }
    else {
        $_[0]->{phone} = $phone; #censorable
    }

    if ($phone =~ /(\d{3}-?\d{7})/ ) {
        $_[0]->{mobile} = ($censor) ? "+358450000".substr($phone, -3) : $1;
    }
    elsif($phone =~ /(\+358\d{2}-?\d{7})/ ) {
        $_[0]->{mobile} = ($censor) ? "+358450000".substr($phone, -3) : $1;
    }
    else {
        $_[0]->{phone} = ($censor) ? "+358450000".substr($phone, -3) : $phone;
    }
}
sub get_phone {
    return $_[0]->{phone};
}
#sub set_phonepro {
#    my $phonepro = $_[0]->{phone};
#    if (! $phonepro) {
#		return;
#    }
#    else {
#		$_[0]->{phonepro} = $phonepro;
#    }    
#}
#sub get_phonepro {
#    return $_[0]->{phonepro};
#}

## These attributes go outside the borrowers-table. Inside the table borrower_attributes.
sub set_extendedAttributes {
    my $cuident = $_[2]->[0];
    my $cuphone2 = $_[2]->[1];
    
    my $extendedAttributesList = '';
    
    ## Figure out the elusive SSN ##
    
    my $ssn;
    if ($cuident =~ /(\d{6}.\d{3}.)/) {
        $ssn = $1;
    }
    #EGDATA-46
    #Somehow due to historical reasons our librarians decided to store the SSN in the mobile -field.
    #We are here to catch the SSN and MIGRATE it! (if cuident doesnt match)
    elsif ($cuphone2 =~ /(\d{6}.\d{3}\w)/) {
        $ssn = $1;
    }#EO EGDATA-46
    else {
        #warn 'Patron id '.$_[0]->{borrowernumber}.": has no SSN!";
        return;
    }
    
    ## Get sex from ssn!
    if ($ssn =~ /\d{6}.\d{2}(\d)./) {
        if ($1 % 2 == 1) {
            $_[0]->{sex} = 'M';
        }
        else {
            $_[0]->{sex} = 'F';
        }
    }
    
    if ($censor) {
        $ssn = sprintf("%.6d",rand (999999)).'-'. sprintf("%.3d",rand (999)).sprintf("%.2d",rand (9));
    }
    
    my $ssnkey = PatronsImportChain::SsnToSsnStore::appendValues( $_[1]->{ssnbatch} , $ssn);
    $extendedAttributesList .= "SSN,$ssnkey,undef";

    ## SSN nailed and ready for migration!    
    
    $_[0]->{extendedAttributes} = $extendedAttributesList;
}
sub get_extendedAttributes {
    return $_[0]->{extendedAttributes};
}

sub set_mobile {
    
    my $liwcusetGsm = $_[1]->{liwcuset}->fetchWithoutWarning(  $_[0]->{borrowernumber} , undef, 'gsm'  );
    if (! $liwcusetGsm) {	#try to determine the available phone number, prioritizing $liwcusetGsm
        ##EGDATA-46
        #Somehow due to historical reasons our librarians decided to store the SSN in the mobile -field.
        #We are here to remedy that. Catch the SSN and ELIMINATE it!
        if ($_[2]->[0] =~ /\d{6}.\d{3}\w/) {
            $_[0]->{mobile} = '';
            return;
        }##EO EGDATA-46
        elsif ($_[2]->[0]) {
            $liwcusetGsm = $_[2]->[0];
        }
        else {
            $_[0]->{mobile} = '' unless $_[0]->{mobile};
            return;
        }
    }
    
        
    if ($censor) {
        my $censored = '';
        if (length $liwcusetGsm > 3) {
            $censored = substr($liwcusetGsm, -3);
        }
        else {
            $censored = 'No Phone';
        }
        $_[0]->{mobile} = "+35845000".$censored;
        $_[0]->{phone} = $_[0]->{mobile} unless $_[0]->{phone}; #MAke sure that there is a phone, which is the primary contact
        #$_[0]->{smsalertnumber} = "+35845000".$censored; #Enabling this will send lots of sms's with bad numbers in Koha via process_message_queue.pl.
    }
    else {
        $_[0]->{mobile} = $liwcusetGsm; #censorable
        $_[0]->{phone} = $_[0]->{mobile} unless $_[0]->{phone}; #Making sure phone exists!
        $_[0]->{smsalertnumber} = $liwcusetGsm; #censorable
    }
}
sub get_mobile {
    return $_[0]->{mobile};
}

sub set_branchcode {
    my $libid;
    my $culocid = $_[2]->[0];

    if(length $culocid == 5) { #If Eno is involved 
        $libid = substr $culocid, 0, 2;
    }
    else {
        $libid = substr $culocid, 0, 1;
    }
    my $licloqde = TranslationTables::liqlocde_translation::resolve(  { libid => $libid, locid => $culocid }  );
    my $oldLocName = $licloqde->[0];
    my $branchcode = $licloqde->[1];
    my $shelvingLocation = $licloqde->[2];

    if ($shelvingLocation eq 'POIS') {
        return 'KILL MEE!';
    }
    if (! $branchcode) {
        $_[0]->separateItemAsVolatile("set_branchcode(): Patron borrowernumber ".$_[0]->{borrowernumber}." has undefined home library with locid = $culocid. Old library is $oldLocName!", 1);
    }

    $_[0]->{branchcode} = $branchcode;
}
sub get_branchcode {
    return $_[0]->{branchcode};
}

sub set_dateofbirth {
    my $dateofbirth = $_[2]->[0];
    my $categorycode = $_[2]->[1];

    if ($dateofbirth) {
        if ($censor) {
            $_[0]->{dateofbirth} = "1234-12-".substr(  CommonRoutines::iso_standardize_date( $dateofbirth ), -2  );
        }
        else {
            $_[0]->{dateofbirth} = CommonRoutines::iso_standardize_date( $dateofbirth );
        }
    }
    #There are various utility categorycodes that don't natively have a date-of-birth.
    #We create a distinct timestamp for such categorycodes. Any other date-of-birthless patron records get the empty/broken dateofbirth.
    else {
        if (! defined $categorycode) {
            $_[0]->{dateofbirth} = CommonRoutines::iso_standardize_date( 1000 );
            $_[0]->separateItemAsVolatile("dateofbirth(): Patron borrowernumber ".$_[0]->{borrowernumber}." has undefined categorycode!", 0);
        }
        elsif ($categorycode == 1 || $categorycode == 3 || $categorycode == 4 || $categorycode == 5 || $categorycode == 9) { #TODO add the user.permission_group id for non-catalogued checkout
            $_[0]->{dateofbirth} = CommonRoutines::iso_standardize_date( 1000 );
        }
        else {
            $_[0]->{dateofbirth} = CommonRoutines::iso_standardize_date( 1000 );
            $_[0]->separateItemAsVolatile("dateofbirth(): Patron borrowernumber ".$_[0]->{borrowernumber}." has no date of birth while categorycode requires it!", 1);
        }
    }
}
sub get_dateofbirth {
    return $_[0]->{dateofbirth};
}

sub set_guarantorid {
    my $guarantorId = $_[2]->[0];
    
    if (! (defined $guarantorId) ) {
        print 'Patron id '.$_[0]->{borrowernumber}.": guarantorid $guarantorId not existing!";
    }
    elsif ($guarantorId < 0) {
        print 'Patron id '.$_[0]->{borrowernumber}.": guarantorid $guarantorId less than 0!";
    }
    elsif (! ($guarantorId =~ /^\d+$/) ) {
        print 'Patron id '.$_[0]->{borrowernumber}.": guarantorid $guarantorId is not a integer!";
    }
    elsif ($guarantorId == 0) {
        #Not everyone has a guarantor. Thus we don't create the attribute.
    }
    else {
        $_[0]->{guarantorid} = $guarantorId;
    }
}
sub get_guarantorid {
    return $_[0]->{guarantorid};
}

sub set_borrowernotes {
    my $borrowernotes = $_[2]->[0];
    
    if (! (defined $borrowernotes) ) {
        warn 'Patron id '.$_[0]->{borrowernumber}.": borrowernotes $borrowernotes not existing!";
    }
    elsif ($borrowernotes eq '0') {
        #It's ok. Not always a patron is note-worthy.
    }
    else {
        $_[0]->{borrowernotes} = $borrowernotes;
    }
}
sub get_borrowernotes {
    return $_[0]->{borrowernotes};
}

sub set_juvenile {
    if ($_[2]->[0] == 6) {	$_[0]->{juvenile} = "t";	}
    else { $_[0]->{juvenile} = "f"; }
}
sub get_juvenile {
    return $_[0]->{juvenile};
}

sub set_dateenrolled {	 #print "[postprocesses.pl->dateenrolled()]=> " . Dumper($_[3]) . "\n"; #DEBUG
    if (! $_[2]->[0]) {
        $_[0]->{dateenrolled} = CommonRoutines::iso_standardize_date( 1000 );
        #$_[0]->separateItemAsVolatile("set_dateenrolled(): Patron borrowernumber ".$_[0]->{borrowernumber}." has no dateenrolled, using timestamp 1000!", 1);
    }
    else {
        $_[0]->{dateenrolled} = CommonRoutines::iso_standardize_date( $_[2]->[0] );
    }
}
sub get_dateenrolled {
    return $_[0]->{dateenrolled};
}

##It is necessary to catch patrons whose cards are expiring so we can check their contact information.
#Introducing a soft expiration timeframe for one year after the migration when all of our patrons cards expire.
#Presuming that 2007 is the year when most cards are given. Cards are given up until now().
#Easing the expiration date gently for the year following migration, by having 2007 migrate in 2 months, and 2013 expire in 12 months.
#This is done cleverly using randomly generating expiration dates.
my $yearLength = 31556926;
my $cardActiveDuration = 3 * $yearLength;
my $now = time() + ($yearLength / 4); #Shift card expirations to start 3 months from now.
my $earliestTimeCardCanBeActive = $now - $cardActiveDuration;
sub set_dateexpiry {
    my $self = $_[0];
    my $cucarddate = $_[2]->[0]; #unix timestamp for the card giving date

    
    #These patrons have no card creation date.
    if (! $cucarddate) {
        $self->{dateexpiry} = CommonRoutines::iso_standardize_date( $now + 2629743); #2629743 is seconds in a month
    }
    #These patrons would expire their priviledges normally anyway
    elsif($cucarddate > $earliestTimeCardCanBeActive ) {
        #Set the expiration date 3 years from the time the card is given
        $self->{dateexpiry} = CommonRoutines::iso_standardize_date( $now + $cardActiveDuration);
    }
    #Now we get to the randomization part.
    else {
        #Get a random time within 1 year from now.
        my $expirationDate = $now + int(  rand() * $yearLength  );
        
        $self->{dateexpiry} = CommonRoutines::iso_standardize_date( $expirationDate );
    }
}
sub get_dateexpiry {
    return $_[0]->{dateexpiry};
}

sub set_last_update_time {
    my $modtime = $_[2]->[0];
    my $debt = $_[2]->[1];
    
    if (! $modtime) {
        $_[0]->{last_update_time} = CommonRoutines::iso_standardize_date( 1000 );
        $_[0]->separateItemAsVolatile("set_last_update_time(): Patron borrowernumber ".$_[0]->{borrowernumber}." has no last_update_time!", 1);
    }
        else {
        $_[0]->{last_update_time} = CommonRoutines::iso_standardize_date( $modtime );
    }
    
    ##EGDATA-90
    if ($modtime < 1199145600) { #If the unix timestamp is less then 1.1.2007 00:00 GMT+0, so this Patron has been unmodified (inactive?) since that date, we might have to delete him.
        no warnings 'numeric';
        if ($debt == 0) { #make sure Perl treats debt as a number. $debt could be like '0,000'
            #my $isGuarantor = $_[1]->{huoltaja}->fetch( $_[0]->{borrowernumber} );
            #if (! $isGuarantor) {
            #	return 'KILL MEE!';
            #}
        }
    }##EO EGDATA-90
}
sub get_last_update_time {
    return $_[0]->{last_update_time};
}

sub set_alias {
    if (! $_[2]->[0]) {
        $_[0]->{alias} = '';
        return;
    }
    $_[0]->{alias} = $_[2]->[0];
}
sub get_alias {
    return $_[0]->{alias};
}

sub set_standing_penalties {
    #we are catching patrons' status1-column and resolving PP states to corresponding Eg states
    
=config.standing_penalty = penalties grantable to patrons for being naughty
 id |                name                |                         label                         |   block_list    | staff_alert | org_depth 
----+------------------------------------+-------------------------------------------------------+-----------------+-------------+-----------
  1 | PATRON_EXCEEDS_FINES               | Patron exceeds fine threshold                         | CIRC|HOLD|RENEW | t           |          
  2 | PATRON_EXCEEDS_OVERDUE_COUNT       | Patron exceeds max overdue item threshold             | CIRC|HOLD|RENEW | t           |          
  3 | PATRON_EXCEEDS_CHECKOUT_COUNT      | Patron exceeds max checked out item threshold         | CIRC            | t           |          
  4 | PATRON_EXCEEDS_COLLECTIONS_WARNING | Patron exceeds pre-collections warning fine threshold | CIRC|HOLD|RENEW | t           |          
 20 | ALERT_NOTE                         | Alerting Note, no blocks                              |                 | t           |          
 21 | SILENT_NOTE                        | Note, no blocks                                       |                 | f           |          
 22 | STAFF_C                            | Alerting block on Circ                                | CIRC            | t           |          
 23 | STAFF_CH                           | Alerting block on Circ and Hold                       | CIRC|HOLD       | t           |          
 24 | STAFF_CR                           | Alerting block on Circ and Renew                      | CIRC|RENEW      | t           |          
 25 | STAFF_CHR                          | Alerting block on Circ, Hold and Renew                | CIRC|HOLD|RENEW | t           |          
 26 | STAFF_HR                           | Alerting block on Hold and Renew                      | HOLD|RENEW      | t           |          
 27 | STAFF_H                            | Alerting block on Hold                                | HOLD            | t           |          
 28 | STAFF_R                            | Alerting block on Renew                               | RENEW           | t           |          
 29 | INVALID_PATRON_ADDRESS             | Patron has an invalid address                         |                 | f           |          
 30 | PATRON_IN_COLLECTIONS              | Patron has been referred to a collections agency      |                 | f           |          
 31 | INVALID_PATRON_EMAIL_ADDRESS       | Patron had an invalid email address                   |                 | t           |         0
 32 | INVALID_PATRON_DAY_PHONE           | Patron had an invalid daytime phone number            |                 | t           |         0
 33 | INVALID_PATRON_EVENING_PHONE       | Patron had an invalid evening phone number            |                 | t           |         0
 34 | INVALID_PATRON_OTHER_PHONE         | Patron had an invalid other phone number              |                 | t           |         0
 
 ##In PP the following statuses apply for the given bits:    (NOTE: 1st bit is at byte[7] and 8th bit is in byte[0])
 no status 		= 0, bit1 0
 ??			= 2, bit2 ?
 deny checkout		= 4, bit3 1 , handled in barred()
 damaged holdings	= 8, bit4 1
 wrong address		= 16, bit5 1
 block holds		= 32, bit6 1
 no self service	= 64, bit7 1
 not in use		= -128, bit8 1 , handled in active()
=cut
    #first the status1
    my $status1 = $_[2]->[0];
    my @byte = CommonRoutines::breakIntegerToBinaryArray($status1);
    my $standing_penalties = '';
    
    $standing_penalties .= "<20>PallasPro:ssa lainaaminen estetty" if ($byte[-3]);
    $standing_penalties .= "<20>PallasPro:ssa turmellut aineistoa" if ($byte[-4]);
    $standing_penalties .= "<29>PallasPro:ssa virheellinen osoite" if ($byte[-5]);
    $standing_penalties .= "<27>PallasPro:ssa varauskielto määritelty" if ($byte[-6]);
    #TODO: no-self-service BLOCK not defined in Evergreen
    $standing_penalties .= "<20>PallasPro:ssa itsepalvelukielto määritelty" if ($byte[-7]);
    #not-active if ($byte[-8]);
    
    if ($standing_penalties) {
        my $breakpoitn;
    }
    
    $_[0]->{standing_penalties} = $standing_penalties;
    
    
    
    # ia ll                   
    #-108 [1, 0, 0, 1, 0, 1, 0, 0] #mitätöity asiakastunnus korvattu
    #112  [0, 1, 1, 1, 0, 0, 0, 0] #lasku lähetetty, maksuja 10€, huomautus, ei-intro-active, 1. kortti
    #112                           #lasku lähetetty, maksuja 13.50€, huomautus, ei-intro-active
    #-112 [1, 0, 0, 1, 0, 0, 0, 0] #mitätöity asiakastunnus korvattu
    #-112                          #
    #-128 [1, 0, 0, 0, 0, 0, 0, 0] #mitätöity asiakastunnus korvattu
    #-80  [1, 0, 1, 1, 0, 0, 0, 0] #vanhentunut kortti
    #16   [0, 0, 0, 1, 0, 0, 0, 0] #2.kortti, viestit vain postitse, eiaikoihin asioinut, 
    #16                            #2.kortti, viestit vain postitse/tekstiviestillä, salanumero, ilmoitus eräpäiovästä spostiin, huollettavia
    #16                            #2.kortti, viestit vain postitse, eiaikoihin asionut
    #-16  [1, 1, 1, 1, 0, 0, 0, 0] #mitätöity asiakastunnus korvattu
    #20   [0, 0, 0, 1, 0, 1, 0, 0] #2.kortti, viestit vain sähköpostitse
    #20                            #2.kortti, viestit vain sähköpostitse, eiaikohin asioinut
    #20                            #2.kortti, viestit vain tekstiviestinä, salanumero
    #32   [0, 0, 1, 0, 0, 0, 0, 0] #
    #4    [0, 0, 0, 0, 0, 1, 0, 0] #2.kortit, 
    #4                             #
    
    #bit8 = inactive, dealed with in active()
    #bit7 = bill sent
    
    #Really hard to figure out.
    my $status2 = $_[2]->[1];
    #???
}
sub get_standing_penalties {
    return $_[0]->{standing_penalties};
}

sub set_smsalertnumber {
    my $smsalertnumber;
    $smsalertnumber = $_[0]->{mobile} if exists $_[0]->{mobile};

    return unless ($smsalertnumber);

    $smsalertnumber =~ s/[^0-9+]//gsmu;
    if ($smsalertnumber =~ /^(\+\d\d\d\d\d|\d\d\d)(\d\d\d\d\d\d\d)$/) {
        $_[0]->{smsalertnumber} = $1.'-'.$2;
    }
    else {
        print 'Patron id '.$_[0]->{borrowernumber}.": Bad smsalertnumber $smsalertnumber!\n";
    }
}
sub get_smsalertnumber {
    return $_[0]->{smsalertnumber};
}


#####FOR actor.usr_address
sub set_usr {
    $_[0]->{usr} = (defined $_[2]->[0]) ? $_[2]->[0] : 'NO ID!';
}
sub get_usr {
    return $_[0]->{usr};
}
=head This is disabled because it is no longer used in our Koha
sub set_streetnumber {
    my $custreet1 = $_[2]->[0];
    my $streetnumber; 
    
    if (! $custreet1) {
        $_[0]->{streetnumber} = '';
    }
    
    if ($custreet1 =~ /^\w+\s(\d+.*?)$/) {
        $streetnumber = $1;
    }
    
    if ($streetnumber) {
        if ($censor) {
            $_[0]->{streetnumber} = $streetnumber; 
        }
        else {
            $_[0]->{streetnumber} = $streetnumber;
        }    	
    }
}
sub get_streetnumber {
    return $_[0]->{streetnumber};
}
=cut
sub set_address {
    my $custreet1 = $_[2]->[0];
    
    if (! $custreet1) {
        $_[0]->{address} = '';
    }
    
    if ($censor) {
        $_[0]->{address} = 'sensuroitu osoite '.substr( $custreet1, -2 ); 
    }
    else {
        $_[0]->{address} = CommonRoutines::name_normalize(  $custreet1  );
    }
}
sub get_address {
    return $_[0]->{address};
}

sub set_city {
    if (! $_[2]->[0]) {
        $_[0]->{city} = 'NO CITY!';
        $_[0]->separateItemAsVolatile("set_city(): Patron borrowernumber ".$_[0]->{borrowernumber}." has no city!", 1);
        return;
    }
    
    if ($_[2]->[0] =~ /[^\d]*\d* (.*)/) {
        $_[0]->{city} = CommonRoutines::name_normalize(  $1  );
    }
    else {
        $_[0]->{city} = CommonRoutines::name_normalize(  $_[2]->[0]  );
    }
}
sub get_city {
    return $_[0]->{city};
}

sub set_state {
    $_[0]->{state} = $_[2]->[0];
}
sub get_state {
    return $_[0]->{state};
}

sub set_country {
    $_[0]->{country} = $_[2]->[0];
}
sub get_country {
    return $_[0]->{country};
}

sub set_zipcode {
    if (! $_[2]->[0]) {
        $_[0]->{zipcode} = 'NO ZIPCODE!';
        $_[0]->separateItemAsVolatile("set_zipcode(): Patron borrowernumber ".$_[0]->{borrowernumber}." has no postcode!", 1);
        return;
    }
    my $postcode = $_[2]->[0];
    if ($postcode =~ /(\d{5})/) {
        if ($censor) {
            $_[0]->{zipcode} = "123".substr($1,-2);
        }
        else {
            $_[0]->{zipcode} = $1;
        }
    }
    else {
        $_[0]->{zipcode} = $postcode;
    }
}
sub get_zipcode {
    return $_[0]->{zipcode};
}

sub set_sex {
    #Set from set_extendedAttributes() when processing ssn
}
sub get_sex {
    return $_[0]->{sex};
}

sub set_privacy {
    $_[0]->{privacy} = $_[2]->[0];
}
sub get_privacy {
    return $_[0]->{privacy};
}

#####FOR actor.usr_note
sub set_creator {
    $_[0]->{creator} = $_[2]->[0];
}
sub get_creator {
    return $_[0]->{creator};
}

sub set_title {
    my $title = $_[2]->[0];
    if (! $title) {
    $_[0]->{title} = '';
    return;
    }
    
    $title = chomp $title;
    if (length $title > 30) {
    $_[0]->{title} = substr $title,0,30;
    }
    else {
    $_[0]->{title} = $title;
    }
}
sub get_title {
    return $_[0]->{title};
}

sub set_value {
    my $value = $_[2]->[0];
    if (! $value) {
    $_[0]->{value} = '';
    return;
    }
    
    #For legacy reasons, some cunote columns have email stored, remove it. It is better taken care of in set_title()
    $value =~ s/([a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\-\.]+)//;
    $_[0]->{value} = $value;
}
sub get_value {
    return $_[0]->{value};
}


#####FOR actor.card
sub set_cardnumber {
    $_[0]->{cardnumber} = buildABarcode(@_);
}
sub get_cardnumber {
    return $_[0]->{cardnumber};
}



####################### END OF ACCESSORS #####################
## starting behavioral methods ##

#not a postprocessor, but used by userid() and cardnumber()
sub buildABarcode {
    my $patronId = $_[2]->[0];
    my $cuident = $_[2]->[1];

    ##If the borrower has an alternate identification, which is not the !!!!SSN!!!!, use that instead.
    #Also make sure that it is a presumed barcode instead of other craziness what typically is put to the cuident-field.
    if ($cuident && $cuident =~ m/(\d{10,})/) { #If the cuident has more than 10 digits, use that as barcode.
        return $cuident;
    }

    #get the first one or two digits that show the initial location where the patron has been granted his card. We cannot use $locid here
    #  because patrons locations could change.
    my $createdLocationId = (length $patronId == 8) ? substr $patronId,0,2 : substr $patronId,0,1;

    #There are some legacy barcodes granted prior to the merging of municipalities, catching them and creating replacements.
    my $nochecknumber; #Patrons from some branches don't have a checknumber attached in the barcode
    my $countyNumber;

    #Check overrides for licloqde-rules
    if ($CFG::CFG->{organization} eq 'pielinen') {
        if ($createdLocationId == 1) { #municipal code 541
            $nochecknumber = 1;
        }
        elsif ($createdLocationId == 2) { #municipal code 422
            $nochecknumber = 1;
        }
        elsif ($createdLocationId == 3) { #municipal code 146
            $nochecknumber = 0;
        }
    }

    unless ($countyNumber) {
        my $licloqde = TranslationTables::liqlocde_translation::resolve(  { libid => $createdLocationId }  );
        $countyNumber = $licloqde->[0];
    }

    my $identifyingNumber = substr $patronId, length $createdLocationId; #get the rest of the integers after the branchid
    my $barcode = ($nochecknumber) ?
                    $countyNumber . "A" . $identifyingNumber :
                    $countyNumber . "A" . $identifyingNumber . CommonRoutines::checksum_modulus_10($identifyingNumber);

    if (! $countyNumber) {
        $_[0]->separateItemAsVolatile("\buildABarcode(): No CountyNumber present for patron borrowernumber : $patronId", 1);
    }

    return $barcode;
}

#Will destroy these MOFOs Justin Case. Should be no circular references etc, but you never know with Perl.
sub DESTROY {
    my $self = shift;
    
    foreach my $k (keys %$self) {
        
        undef $self->{$k};
        delete $self->{$k};
    }
}

#patron should be stored in this format so it can be loaded to perl.
#$VAR1 = bless( {'categorycode' => 18,'creator' => 1,'state' => "It\x{e4}-Suomi",'standing_penalties' => '','email' => '','id' => '1007112','extendedAttributes' => '111222-333A','value' => '','active' => 't','barcode' => '167A0071129','zipcode' => '12360','branchcode' => 'RAN','dateofbirth' => '1234-12-02','title' => '','alias' => '','phone' => '','userid' => '167A0071129','juvenile' => 'f','surname' => 'Rajan','firstname' => 'Sherly','city' => 'JOENSUU','usr' => '1007112','country' => 'Suomi','ident_type' => 2,'dateenrolled' => '2006-2-22 0:0:0+02','last_update_time' => '2006-2-22 14:56:14+02','address' => 'sensuroitu osoite  9','mobile' => '','password' => '1234','firstname' => '','barred' => 'f'}, 'Patron' );
sub toString {
    
    my $p = shift;
    
    my $objectString = '$VAR1 = bless( {';
    
    for my $key (sort keys %$p) {
    #print $p->{$key};
    $p->{$key} =~ s/'/\\'/g; #Sanitate quotation marks
    $p->{$key} = Encode::decode_utf8($p->{$key}); # set the flag
    #print "\n";
    
    $objectString .= "'$key' => '$p->{$key}',";
    }
    $objectString =~ s/,$//; #remove last comma.
    $objectString .= "}, 'Item' );";
    
    #(utf8::is_utf8($objectString)) ?print "(=D)" : print "(:()";
    
    #$objectString = Encode::decode_utf8($objectString); # set the flag
    return $objectString;
}

#Sometimes we cannot be sure about an Item. It has quirky attributes or missing fields etc.
#Isolate such Items from the working dataset so they can be more easily detected manually and reacted upon.
#This is done by setting the library designation (circ_lib) to 'JOKUNEN'.
sub separateItemAsVolatile {
    my $errorStr = $_[1];
    my $printItemDump = $_[2];
    
    if ($printItemDump) {
        $log->warning( $errorStr."\n".$_[0]->toString()."\n");
    }
    else {
        $log->warning( $errorStr."\n");
    }
    
    $_[0]->{volatile} = '1';
    $_[0]->{branchcode} = 'KONVERSIO';
}

1;
