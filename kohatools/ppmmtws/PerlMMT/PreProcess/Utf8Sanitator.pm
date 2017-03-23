package PreProcess::Utf8Sanitator;

use strict;
use warnings;
use utf8;
use HTML::Entities;
        
    
sub sanitate {

    my $sourceFile = shift;
    my $destinationFile = shift;
    
    open my $IN, "<:utf8",$sourceFile;
    open my $OUT, ">:utf8",$destinationFile;
    
    while (<$IN>) {
        my $row = $_;
        next() if length $row < 3;
        
        #remove any characters which don't fit in.
        sub InNotPrintable {
            return <<END;
!utf8::Print
-utf8::Blank
END
        }
        $row =~ s/\p{InNotPrintable}//g;
        #Encoding XML entities is a bad idea, since it will screw up parts of MMT.
        #$row = HTML::Entities::encode_entities($row, "&<>'\"");
        
        
        
        print $OUT $row."\n";
    }
    
    close $IN;
    close $OUT;
}

###LEGACY###
#old validators prior to this new hardcore remove all method.
#Feel free to remove this function if current utf8-sanitator works fine.
sub oldValidators {
    my $row;
    my $sourceFile;
        #my $hexstring = '';
        #foreach my $c (split('', $row)) {
        #    my $g = unpack('U0U*', $c);
        #    my $z = pack('U0U*', $g);
        #    my $hex = hex( sprintf('%2.2x', unpack('U0U*', $c)) );
        #    $hexstring .= sprintf('%2.2x', unpack('U0U*', $c)) .' ';
        #}
    
        #remove the pesky \u001F INFORMATION SEPARATOR ONE messing up everything in PallasPro-To-ISO2709
        if ($row =~ s/\x{001F}//g) {
            warn("fixed one \\u001F in $sourceFile on this row:\n     $row");
        }
        #data-link escape is nasty as well
        if ($row =~ s/\x{0010}//g) {
            warn("fixed one \\u0010 in $sourceFile on this row:\n     $row");
        }
        #Where do we get all of these? \u0012 DEVICE CONTROL TWO?
        if ($row =~ s/\x{0012}//g) {
            warn("fixed one \\u0012 in $sourceFile on this row:\n     $row");
        }
        #if ($row =~ s/\x{0084}//g) {
        #    my $hexstring = '';
        #    foreach my $c (split('', $row)) {
        #	$hexstring .= sprintf('%2.2x', unpack('U0U*', $c)) .' ';
        #    }
        #    warn("fixed one \\u0084 in $sourceFile on this row:\n     $row");
        #}
}
"0RxR0";