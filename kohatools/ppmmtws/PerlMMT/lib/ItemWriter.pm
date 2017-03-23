####################
##! IN-THIS-FILE !##
####################
## This ItemWriter writes both Item.pm and Patron.pm -objects to a file.
## This file is INSERTed to the EG DB.
## The purpose of this is to have a output of the values that are meant for the DB for visual validation.
package ItemWriter;

use warnings;
use strict;
#use diagnostics;
use utf8;

use Encode;
use LiteLogger;

sub new {
    my $class = shift;
    my $s = {};
    
    $s->{log} = LiteLogger->new({package => 'ItemWriter'});
    $s->{baseFilePath} = shift;
    if ( $s->{baseFilePath} =~ /(.+\/).+$/ ) {
        $s->{volatileFilePath} = $1;
    }
    else {
        die( 'ItemWriter couldnt generate $volatileFilePath from $baseFilePath='.$s->{baseFilePath} );
    }
    
    open(my $VOLATILEFILE, ">:utf8", $s->{volatileFilePath}.'volatile') or die('couldnt open '.$s->{volatileFilePath}.'volatile'.' for writing');
    $s->{VOLATILEFILE} = $VOLATILEFILE;

    bless($s, $class);
    return $s;
}

sub setNewChunk {
    close $_[0]->{LICCOPY} if defined $_[0]->{LICCOPY};
    open($_[0]->{LICCOPY}, ">:utf8", $_[0]->{baseFilePath}.$_[1]) or die $!.": ".$_[0]->{baseFilePath}.$_[1]; #reads the marc items file
    select((select($_[0]->{LICCOPY}), $|=1)[0]); #make filehandle hot!
}

sub writeItems {
    my $s = shift;
    my $items = shift;
    my $fh = $s->{LICCOPY};
    my $vfh = $s->{VOLATILEFILE};
    
    if (ref $items eq 'HASH') {
        foreach (sort keys %$items) {
            my $item = $items->{$_};
            
            my $itemString = $item->toString() . "\n";
            #is really utf8, but the flag is somehow lost during processing
            #$itemString = Encode::decode_utf8($itemString); # set the flag
            
            if ($item->{volatile} && ! $CFG::CFG->{'MigrateVolatile'}) {
                print $vfh $itemString;
            }
            else {
                print $fh $itemString;
            }
        }
    }
    if (ref $items eq 'ARRAY') {
        foreach my $item (@$items) {
            
            my $itemString = $item->toString() . "\n";
            #is really utf8, but the flag is somehow lost during processing
            $itemString = Encode::decode_utf8($itemString); # set the flag
            
            if ($item->{volatile} && ! $CFG::CFG->{'MigrateVolatile'}) {    
                print $vfh $itemString;
            }
            else {
                print $fh $itemString;
            }
        }
    }
    
}

sub _DESTROY {
    close $_[0]->{VOLATILEFILE};
}
1;