package CommonRoutines;
use strict;
use warnings;
use utf8;

use Switch;
use POSIX;
use Time::Local;
use Carp;
use Encode;
use Text::Autoformat;
use XML::Simple;



#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

=head1 IN THIS FILE
Contains common utility subroutines used in various stages of this tool.
=cut

my @todayLocaltime = localtime();

sub trim {
	$_[0] =~ s/^\s*//;
	$_[0] =~ s/\s*$//;
	return $_[0];
}

sub iso_standardize_yymm ($) {
	my $timestamp = $_[0];
	my ($year, $month);
	if ($timestamp =~ /(\d?\d\d)(\d\d)/) {
		if ($1 >= 100) {
			$year = '20'. substr $1,1,2;
		}
		else {
			$year = '19'.$1;
		}
		$month = $2;
		
		return $year . '-' . $month . '-01 23:59:00+02';
	}
}

sub iso_standardize_date ($) {

    my $timestamp = $_[0];
    if (length $_[0] == 8) { #we have a date in format yyyymmdd
        if ($_[0] =~ /(\d\d\d\d)(\d\d)(\d\d)/) {
            my $year = $1;
            my $month = $2;
            my $day = $3;
            if ($month eq '00' || $day eq '00') {
                $month = '01' if $month eq '00';
                $day = '01' if $day eq '00';
                print "Date $1$2$3 ($day.$month.$year) normalized to $year$month$day";
            }

            $timestamp = yyyymmdd_to_unix_timestamp($year, $month, $day);
        }
    }
    #we have a unix timestamp
    my ($sec, $min, $hour, $day,$month,$year) = (localtime( $timestamp ))[0,1,2,3,4,5];
    return $year+1900 . "-" . ($month+1) . "-$day $hour:$min:$sec+02";
}
sub yyyymmdd_to_unix_timestamp {
    my $year = $_[0];
    my $month = $_[1];
    my $day = $_[2];

    my @errors;
    if ($year == 9999) { #some entries are "99999999", so this kinda sucks. Catching these entries and modifying them with proper max date.
        $year = $todayLocaltime[5]+1900 + 50; #Get the year 50 years from now. This should be ample time for all the professors to return their forever-loaned books.
        push @errors, 'year9999->'.$year;
    }
    if ($month > 12) {
        $month = 12;
        push @errors, 'month99->12';
    }
    if ($day > 31) {
        if ($month != 12) {
            $day = 28;
            push @errors, 'day99->28';
        }
        else {
            $day = 31;
            push @errors, 'day99->31'; #Koha uses datetime 9999-12-31 to mark some debarrments and forever active things.
        }
    }
    print join(', ', @errors)."\n" if scalar(@errors);
    return Time::Local::timelocal(59, 59, 23, $day, ($month-1), $year); #sec, min, hour set to midnight. Typically we want the day to end at midnight instead of during the first second of the day.
}

# Removes the second date from the first given date
# Param1 a unix timestamp or a yyyymmdd-format date
# Param2 a unix timestamp or a yyyymmdd-format date
# Param3 a flag to tell in which format this interval is returned. 'i' = postgresql interval notation (DEFAULT), 's' = difference in seconds
# Returns the difference
sub subtract_dates ($$$) {
	
	sub validate_timestamp {
		if (length $_[0] == 8) { #we have a date in format yyyymmdd
			if ($_[0] =~ /(\d\d\d\d)(\d\d)(\d\d)/) {
				return yyyymmdd_to_unix_timestamp($1, $2, $3);
			}
		}
		else { #we have a unix timestamp
			return $_[0];
		}
	}
	
	my $timestamp1 = validate_timestamp($_[0]);
	my $timestamp2 = validate_timestamp($_[1]);
	my $interval = $timestamp2 - $timestamp1; #interval in seconds
	
	if ( !(defined $_[2]) || $_[2] eq 'i' ) {
		my $days = $interval / (60 * 60 * 24);
		return $days.' days';
	}
	if ($_[2] eq 's') {
		return $interval;
	}
}

sub checksum_modulus_10 {
	my $idnum = $_[0];
	my @digits = split '',$idnum;
	my $checksum;
	
	#calculate the checksum
	my $sum = 0;
	for (my $i=0 ; $i<@digits ; $i++) {
		
		my $weight = 0;
		
		#if a paired index, because indexes start from 0
		if($i % 2 == 1) {
			$weight = 1;
		}
		#must be a pairless index
		else {
			$weight = 2;
		}
		
		$sum += $weight * $digits[$i];
	}
	$checksum = $sum % 10;
	
	return $checksum;	
}

sub find_marc_field {
	my $marc = $_[0];
	my $sourceMarc = $_[1];
	my $marcFieldsLastIndex = @{$marc->{'fields'}}-1;
		for(my $i = 0 ; $i <= $marcFieldsLastIndex ; $i++) {
			if($marc->{'fields'}->[$i] =~ m/$sourceMarc/) {
				return $i;
				last;
			}
		} 
	return undef;
}

#used to break status integers to their binary representatives
sub breakIntegerToBinaryArray {
	my $status = $_[0];
	my @byte = split '', substr( unpack("B8", pack("i",$status)), -8 );
	return @byte;
}


#Get the highest docId from the sorted-by-docId licmarca.kir
sub getHighestFreeDocid {
    my $docId;
    open CMD, 'tail -n 1 '.shift().' |' or die 'Failed to open pipeline';
    while(<CMD>) {
	$docId = $1 if ($_ =~ /^(\d+)\s/);
    }
    close CMD;
    return $docId;
}

##Name normalizer.
##transforms the given sTrINg to lower case with every word starting character in UPPER CASE
sub name_normalize {
	
	return '' if (! $_[0]);
	my $s = $_[0];
	$s =~ s/(\w+)/\u\L$1/g;
	#Text::Autoformat::autoformat(shift(), { case => 'title' });
	#Somehow Text::Autoformat insists on adding extra newlines at the end of line?
	
	$s = trim($s);

	return $s;
}

=head3 Replace the character in the given position with the substitute string.
=item @Param1 the string scalar.
=item @param2 the location scalar starting from 0 which to substitute
=item @param3 the substitute string used to make the substitution
=cut
sub characterReplace($$$) {
	my $str = $_[0];
	$str =~ s/(?<=^.{$_[1]})./$_[2]/;
	return $str;
}

sub readConfig($) {
	my $jsonConfigFilePath = shift;
	
	open(CONFIG, '<', $jsonConfigFilePath) or die "Couldn't open the config file from $jsonConfigFilePath!";
	
	my $jsonContent;
	-f CONFIG and sysread( CONFIG, $jsonContent, -s CONFIG );
		
	my $decoded = XML::Simple::XMLin( $jsonContent );
	
	close CONFIG;
	
	return $decoded;
}

1;
