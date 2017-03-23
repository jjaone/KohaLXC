package PreProcess::SourceSanitizer;

use strict;
use warnings;
use bytes;

use POSIX;

#statistics for removeLengthIndicator to collect and display
my $statistics = {};
$statistics->{bruteforced} = 0;
$statistics->{approximated} = 0;
$statistics->{calculated} = 0;


sub sanitizeRows {
    
    my $sourceFile = shift;
    my $destinationFile = shift;
    my $expectedColumnCount = shift;
    my $columnsWithLengthIndicators = shift;
    
    open my $IN, "<:bytes",$sourceFile or die print('Cant open '.$sourceFile.' '.$!);
    open my $OUT, ">:bytes",$destinationFile or die print('Cant open '.$destinationFile.' '.$!);
    
    while (<$IN>) {
        my $row = $_;

        next() if ($row =~ m/^\s*$/); #Skip empty rows /r/n for licmarca
	
		$row =~ s/\n\r?$//;
        
        ##Fix rows that have been broken by newline characters
        my $currentCols = getCols($row);
        
        if ( !($currentCols == $expectedColumnCount) ) { #if we didn't get as many columns as we should have, there is a problem
            $row = repairRow($IN, $expectedColumnCount, $row);
            next() if ($row eq "<UNREPAIRABLE>");
            $row = rebuildLengthIndicators($row);
        }
	
        
        ##Remove length_indicators from designated columns
		if (ref $columnsWithLengthIndicators eq 'ARRAY') {
			
			$row = removeLengthIndicators(\$row, $columnsWithLengthIndicators);
		}
	
        print $OUT $row . "\n";
    }
    
    close $IN;
    close $OUT;
    
    print "\nStatistics of removeLengthIndicator:\ncalculated: $statistics->{calculated}, approximated: $statistics->{approximated}, bruteforced: $statistics->{bruteforced}\n";

}


=head SYNOPSIS
We iterate the whole file, counting how many columns we find on each row.
If we get the expected amount of comluns we can move to a new row. This row is structurally intact.
When we find too few columns, fix this by appending new rows to the previous until we have enough columns. Hence the row is repaired.
If we get too many columns in one merged row, we are fucked and this row is discarded. Hence it is unrepairable.
We might get a row having the required amount of columns while trying to repair an existing row. The old one is unrepairable and the new one is kept.
=cut
sub repairRow {
    my $fileStream = shift;
    my $expectedColumnCount = shift;
    
    my $oldRow = shift;
    $oldRow =~ s/\R//g;
    my $oldCols = getCols($oldRow);
    my $newRow;
    my $newCols;

    # count the number of tabs. We know each column, except first one, is preceded by a tab, so tabcount+1 equals column count.
    sub getCols {
        my $cols = () = shift =~ /\t/g;
        return ++$cols;
    }
    
    my $pullNewRow = sub {
        #get a new row and see if it is enough to fill out missing columns
        $newRow = <$fileStream>;
        $newRow =~ s/\R//g;
        $newCols = getCols($newRow);
        if ( $newCols == $expectedColumnCount ) { #the new row is actually a whole row. So the previous one must be a mutant monster from Ingres space
            #Discard the old bastarrd!
            $oldRow = "";
            return "V"; #V for Victory!
        }
        return "N"; #N for Not yet!
    };

    while ( $oldCols < $expectedColumnCount ) { #Still we don't have enough columns in our row, somebody is screwing with us!
        
        return $newRow if &$pullNewRow() eq "V";
        
        $oldRow .= $newRow;
        $oldCols = getCols($oldRow);
        #lets pull some more rows
    }
    
    if ( $oldCols == $expectedColumnCount ) { #Yay! We got a whole row by combining scraps!
        return $oldRow;
    }
    else { #Now we have too many columns! We are fucked!
        #Really no idea what to do. Let's hope no such cases appear
        #for now just discard everything and hope we get a better row next time
        return "<UNREPAIRABLE>";
    }
}

sub rebuildLengthIndicators {
    my @row = split /\t/,shift;
    for (my $i=0 ; $i<@row ; $i++) {
        if ($row[$i] =~ m/\s*(\d+)(\D+)/) { #We can suspect a length_indicator here, because this column starts with digits but is not fully digits.
            
            if ($1 == length $2) { #if the indicator matches the payloads length, is cool!
                
            }
            else {
                print "\nrepaired length_indicator: ";
                $row[$i] = (length $2) . $2;
                print $row[$i];
            }
        }
    }
    return join "\t", @row;
}

sub removeLengthIndicators {
    
    my @columns = split('\t', ${$_[0]});
	
	if ($columns[0] =~ /^\s*?18274\s*?$/) {
		my $break;
	}
	
	my %trimmingPlan;
	foreach my $i (0..(@columns-1)) { # a list of indexes that need to be trimmed. We need this so we can exclude certain columns from trimming
		$trimmingPlan{$i} = 1;		#by default plan all columns to be trimmed
	}
    #Iterate all the column indexes defined in PreProcessConfig.pm and remove the length_indicator
    foreach my $a (@{$_[1]}) {
		my $i;
		#check for special directives from PreProcessConfig.pm
		if (ref $a eq 'ARRAY') {
			if ($a->[1] eq 'noTrim') {
				delete $trimmingPlan{$a->[0]};
			}
			$i = $a->[0];
		}
		else {
			$i = $a;
		}
		#only remove spaces from the beginning of the row, as accidental spaces are counted as characters in remove_length_indicator()
		$columns[$i] =~ s/^\s*//;
		
		next() if (length $columns[$i] < 2);
		
		$columns[$i] = remove_length_indicator($columns[$i]);
    }
    
    #Trim columns
    foreach my $i (keys %trimmingPlan) {
		$columns[$i] =~ s/^\s*//;
		$columns[$i] =~ s/\s*$//;
    }
    
    return join "\t",@columns;
}

=head1 SYNOPSIS
A generic function to remove the string length indicator in the beginning of a string.
Indicator length varies according to the length if the string, with various thresholds 
when moving from tens to hundreds to thousands etc where actual string length is more 
than the indicator length. This function returns the correct result even in such treshold
cases.

@param1 string to remove the length indicator from.
@return string without length indicator or undef if no indicator found
=cut
sub remove_length_indicator {

	if(! (defined $_[0])) {
	    return undef; 
	}

	my $p1 = $_[0];
	
	my $l;
	$l = length($p1);
	my $logL = log($l)/log(10);
	
	my $il; #indicatorLength
	
	#find out how many characters are used to display the line length
	my $g = ceil($logL) -1 ; #get the amount of characters needed to show the length of this line
	my $h = "1"; #string to build a number by appending zeroes for each zero in the line length number. eg. $h = 1 . 0 . 0 for hundreds long line 
	for(1..$g) {
		$h .= "0";
	}
	if($l <= $h+$g) {
		$il = $g ;
	}
	else {
		$il = $g+1;
	}
	#if the starting characters are actual digits and if the length indicator
	#actually is correct, so we wont accidentally parse some string with no length indicator at all.
	if ($p1 =~ m/^(\d{$il})/ && $1 == $l-$il) {
		$statistics->{calculated}++;
		return substr($p1, $il);
	}
	#We can give some variance to the length indicator accuracy. It seems to be impossible/unreasonably difficult to nail the length indicator for some strings. We can tolerate
	#some variance in accuracy with longer strings. Especially now that we know which columns have a length indicator, so we don't have to apply this algorith for every case.
	elsif ($p1 =~ m/^(\d{$il})/   &&   $1 < $l-$il + $logL +1   &&   $1 > $l-$il + $logL -1) {
	       #Make sure starts with digits && fits between upper fuzzy boundary && lower fuzzy boundary
	    $statistics->{approximated}++;
	    
	    print "\nAPPROXIMATED: $p1";

	    while (  $il >= 0  &&  !($p1 =~ /^\d{$il}/)  ) {
		$il--;
		#rewind the indicator_length $il to a spot where it matches only digits, so we wont accidentally remove characters
	    }
	    my $approximation = substr($p1, $il);
	    return $approximation;

	}
	else {
	    
	    #bruteforce it
	    $statistics->{bruteforced}++;
	    
	    print "\nBRUTED: $p1";
	    
	    while (  $il >= 0  &&  !($p1 =~ /^\d{$il}/)  ) {
		$il--;
	        #rewind the indicator_length $il to a spot where it matches only digits, so we wont accidentally remove characters
	    }
	    my $approximation = substr($p1, $il);
	    return $approximation;
	}
}

"R0x0R";