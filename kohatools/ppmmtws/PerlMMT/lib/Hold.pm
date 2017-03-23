package Hold;

use warnings;
use strict;
#use diagnostics;
use utf8;
use POSIX 'strftime';

use Data::Dumper;
use Encode;

use CommonRoutines;
use LiteLogger;

my $log;
sub initPackageVariables {
    $log = LiteLogger->new({package => 'Hold'});
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Purity = 1;
}

#Share the current time
our $now = strftime '%Y%m%d.', localtime;

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

sub set_id { #rvresid
    my $rvresid = $_[2]->[0];
    if ($rvresid) {
        $_[0]->{id} = $rvresid; #Store the lilresrv.kir->rvresid for debugging. This is not needed during migration.
    }
    else {
        $log->warning('Hold has not id!');
    }
}
sub get_id {
    return $_[0]->{id};
}

sub set_borrowernumber { #rvcustid
    my $custid = $_[2]->[0];

    if ($custid) {
        $_[0]->{borrowernumber} = $custid;		
    }
    else { #we don't negotiate if there is no borrowerid
        return 'KILL MEE!';
    }
}
sub get_borrowernumber {
    return $_[0]->{borrowernumber};
}

sub set_status {
    my $status1 = $_[2]->[0];
    my $status2 = $_[2]->[1];

    if ($status1 == -30) {
        $_[0]->{status} = 'LAINATTU'; #Currently checked out
        return 'KILL MEE!'; #Dont migrate checked out holds!
    }
    elsif ($status1 == -20) {
        $_[0]->{status} = 'NOUTAMATTA'; #Hold hasn't been claimed
        $_[0]->{found} = 'W';
        $_[0]->{priority} = '0'; #make sure these holds are targeted firstly!
    }
    elsif ($status1 == -10) {
        $_[0]->{status} = 'VANHENTUNUT'; #Hold has expired
    }
    elsif ($status1 == 0) {
        $_[0]->{status} = 'VOIMASSA'; #Hold has been placed and is waiting
    }
    elsif ($status1 == 1) {
        $_[0]->{status} = 'VOIMASSA'; #Hold has been placed and is waiting
    }
    elsif ($status1 == 10) {
        $_[0]->{status} = 'NOUDETTAVANA'; #Hold is awaiting for pickup
        $_[0]->{found} = 'W';
        $_[0]->{priority} = '0'; #make sure these holds are targeted firstly!
        $_[0]->{enque_letter} = 1; #Make sure to queue a notification for this item in the Koha part of migration!
        unless ($_[0]->get_itemnumber()) {
            $log->warning('Hold id:'.$_[0]->{id}.' has status "'.$_[0]->{status}.'" and is missing an itemnumber?');
        }
    }
    elsif ($status1 == 11) {
        $_[0]->{status} = 'NOUDETTAVANA'; #Hold is awaiting for pickup
        $_[0]->{found} = 'W';
        $_[0]->{priority} = '0'; #make sure these holds are targeted firstly!
        $_[0]->{enque_letter} = 1; #Make sure to queue a notification for this item in the Koha part of migration!
        unless ($_[0]->get_itemnumber()) {
            $log->warning('Hold id:'.$_[0]->{id}.' has status "'.$_[0]->{status}.'" and is missing an itemnumber?');
        }
    }
    elsif ($status1 == 20) {
        $_[0]->{status} = 'ILMOITETTU'; #Hold is awaiting and a notification is sent
        $_[0]->{priority} = '0'; #make sure these holds are targeted firstly!
        $_[0]->{found} = 'W';
        unless ($_[0]->get_itemnumber()) {
            $log->warning('Hold id:'.$_[0]->{id}.' has status "'.$_[0]->{status}.'" and is missing an itemnumber?');
        }
    }
    elsif ($status1 == 30) {
        $_[0]->{status} = 'LAINATTU'; #Currently checked out
        return 'KILL MEE!'; #Dont migrate checked out holds!
    }
    elsif ($status1 == 40) {
        $_[0]->{status} = 'CRAZYPSYCHO'; #No idea what this does, it is not visible in PP
        return 'KILL MEE!'; #Don't migrate these unidentified hidden holds!
    }
    elsif ($status1 == 100) {
        $_[0]->{status} = 'SHOULDNT HAVE A BORROWERNUMBER SO IS DROPPED';
    }
    else {
        $_[0]->{status} = 'UNKNOWN'; #This status hasn't been identified yet
        $log->warning('Hold id:'.$_[0]->{id}.' has a unknown status1: '.$status1);
    }
    $_[0]->{reservenotes} = $_[0]->{status} if exists $_[0]->{status};
}
sub get_status {
    return $_[0]->{status};
}

sub set_reservedate {       #rvresdate
    my $resdate = $_[2]->[0];
    
    if (defined $resdate && length $resdate == 8) {
        $_[0]->{reservedate} = CommonRoutines::iso_standardize_date( $resdate );
    }
    else {
        $log->warning('Hold id:'.$_[0]->{id}.' has a bad reserve date: '.$resdate);
    }
}
sub get_reservedate {
    return $_[0]->{reservedate};
}

sub set_biblionumber {       #rvdocid
    my $docid = $_[2]->[0];
    if ($docid) {
        $_[0]->{biblionumber} = $docid;
    }
    else { #we don't negotiate if there is no biblionumber
        return 'KILL MEE!';
    }
}
sub get_biblionumber {
    return $_[0]->{biblionumber};
}

sub set_constrainttype {     #always a
    $_[0]->{constrainttype} = $_[2]->[0];
}
sub get_constrainttype {
    return $_[0]->{constrainttype};
}

sub set_branchcode {         #rvlocid
    my $locid = $_[2]->[0];
    my $libid;
    
    if(length $locid == 5) { #If Eno is involved 
        $libid = substr $locid, 0, 2;
    }
    else {
        $libid = substr $locid, 0, 1;
    }
    my $licloqde = TranslationTables::liqlocde_translation::resolve(  { libid => $libid, locid => $locid }  );
    my $branchcode = $licloqde->[1];
    my $shelvingLocation = $licloqde->[2];

    if ($shelvingLocation eq 'POIS') {
        return 'KILL MEE!';
    }
    if ($branchcode) {
        $_[0]->{branchcode} = $branchcode;
    }
    else {
        $log->warning('Hold id:'.$_[0]->{id}.' has a bad branchcode: '.$locid);
    }
}
sub get_branchcode {
    return $_[0]->{branchcode};
}

sub set_priority {          #rvresdate, first come first serve basis
    my $resdate = $_[2]->[0];
    
    if (! exists $_[0]->{priority}) {
        $_[0]->{priority} = 3;
    }
}
sub get_priority {
    return $_[0]->{priority};
}

sub set_itemnumber {       #rvcopyid
    my $copyid = $_[2]->[0];
    
    if ($copyid) {
        #make negative copyid's positive, as they are normalized in ItemsImportChain as well.
        if ($copyid < 0) {
            $_[0]->{itemnumber} = -1 * $copyid;
        }
        else {
            $_[0]->{itemnumber} = $copyid;
        }
    }	
}
sub get_itemnumber {
    return $_[0]->{itemnumber};
}

sub set_expirationdate {   #rvduedate maybe??
    my $duedate = $_[2]->[0];
    
    #if ($duedate <= $now) {
    #	$_[0]->{expirationdate} = CommonRoutines::iso_standardize_date( $duedate );
    #}
    
}
sub get_expirationdate {
    #return $_[0]->{expirationdate};
    return "not in use";
}

sub set_waitingdate {

    #Fake this to an arbitrarily low date to make koha catch these as expired holds.
    if (  $_[0]->{status} && ($_[0]->{status} eq 'VANHENTUNUT'  ||  $_[0]->{status} eq 'NOUTAMATTA')  ) {
        $_[0]->{waitingdate} = CommonRoutines::iso_standardize_date( '20140330' );
        $_[0]->{found} = 'W';
        $_[0]->{priority} = '0';
    }
    #Couldn't find the proper date when this status has been established, so using NOW()
    if (  $_[0]->{status} && ($_[0]->{status} eq 'NOUDETTAVANA' || $_[0]->{status} eq 'ILMOITETTU')  ) {
        $_[0]->{waitingdate} = CommonRoutines::iso_standardize_date( time );
    }
}
sub get_waitingdate {
    return $_[0]->{waitingdate};
}




####################### END OF ACCESSORS #####################
## starting behavioral methods ##

#Will destroy these MOFOs Justin Case. Should be no circular references etc, but you never know with Perl.
sub DESTROY {
    my $self = shift;
    
    foreach my $k (keys %$self) {
        
        undef $self->{$k};
        delete $self->{$k};
    }
}

sub toString {
    
    my $p = shift;
    
    my $objectString = '$VAR1 = bless( {';
    
    for my $key (sort keys %$p) {
        if (exists $p->{$key}) {
        
            #print $p->{$key};
            $p->{$key} =~ s/'/\\'/g; #Sanitate quotation marks
            $p->{$key} = Encode::decode_utf8($p->{$key}); # set the flag
            #print "\n";
            
            $objectString .= "'$key' => '$p->{$key}',";
        }
        else {
            warn 'Item with barcode '.$p->{barcode}.': Has a key '.$key.' with no value?!';
        }
    }
    $objectString =~ s/,$//; #remove last comma.
    $objectString .= "}, 'Item' );";
    
    #(utf8::is_utf8($objectString)) ?print "(=D)" : print "(:()";
    
    #$objectString = Encode::decode_utf8($objectString); # set the flag
    return $objectString;
}

#Sometimes we cannot be sure about an Item. It has quirky attributes or missing fields etc.
#Isolate such Items from the working dataset so they can be more easily detected manually and reacted upon.
sub separateItemAsVolatile {
    my $errorStr = $_[1];
    
    $log->warning( $errorStr . $_[0]->toString()."\n" );
    
    $_[0]->{volatile} = '1';
    $_[0]->{home_ou} = 'KONVERSIO';
}

1;