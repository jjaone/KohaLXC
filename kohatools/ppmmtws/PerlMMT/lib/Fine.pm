package Fine;

use warnings;
use strict;
#use diagnostics;
use utf8;
use POSIX qw(strftime);

use Data::Dumper;
use Encode;

use CommonRoutines;
use LiteLogger;

my $log;
sub initPackageVariables {
    $log = LiteLogger->new({package => 'Fine'});
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

sub set_borrowernumber {
    my $custid = $_[2]->[0];

    if ($custid) {
        if ($custid =~ /^\d+$/) {
            $_[0]->{borrowernumber} = $custid;
        }
        else {
            $log->warning( "Borrowernumber '$custid' is not a positive digit. Skipping." );
            return 'KILL MEE!';
        }
    }
    else { #we don't negotiate if there is no borrowerid
        return 'KILL MEE!';
    }
}
sub get_borrowernumber {
    return $_[0]->{borrowernumber};
}

sub set_date {
    my $cddate = $_[2]->[0];
    my $cdtime = $_[2]->[1];

    unless (defined $cddate && $cddate =~ /^\d{8}$/) {
        $log->warning('Fine for borrower "'.$_[0]->get_borrowernumber().'" has a bad date: "'.$cddate.'". Skipping.');
        return 'KILL MEE!';
    }
    unless (defined $cdtime && $cdtime =~ /^\d{4}$/) {
        #$log->warning('Fine for borrower "'.$_[0]->get_borrowernumber().'" has a bad time: "'.$cdtime.'". Using 12:00.');
        $cdtime = '1200';
    }
    my $date = CommonRoutines::iso_standardize_date( $cddate );
    my $hour = substr($cdtime,0,2);
    my $minute = substr($cdtime,2,2);

    $_[0]->{date} = $date.'T'.$hour.':'.$minute.':00';
}
sub get_date {
    return $_[0]->{date};
}

sub set_amount {
    my $cdamount = $_[2]->[0];

    if ($cdamount) {
        if ($cdamount =~ /^-?\d+([,.]\d+)?$/) { #Has to be an positive or negative double
            $cdamount =~ s/,/./g;
            $_[0]->{amount} = $cdamount; #Perl demands comma separated doubles.
        }
        else {
            $log->warning( 'Fine for borrowernumber "'.$_[0]->get_borrowernumber().'" has a bad fine amount "'.$cdamount.'". Skipping.' );
            return 'KILL MEE!';
        }
    }
    else { #No point in migrating a fine with nothing on it.
        return 'KILL MEE!';
    }
}
sub get_amount {
    return $_[0]->{amount};
}

sub set_description {
    my $description = $_[2]->[0];
    $description =~ s/\\/-/g;
    $_[0]->{description} = $description;
}
sub get_description {
    return $_[0]->{description};
}

sub set_accounttype {
    $_[0]->{accounttype} = $_[2]->[0];
}
sub get_accounttype {
    return $_[0]->{accounttype};
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