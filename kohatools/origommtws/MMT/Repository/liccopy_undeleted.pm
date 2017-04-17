###NOT IN USE
###IN-DB Repositories seem to be really slow to load and use compared to in memory.

package Repository::liccopy_undeleted;

use warnings;
use strict;
use utf8;
use Repository::SingletonRepository;
use CommonRoutines;

our @ISA = ('Repository::SingletonRepository');

sub checkInsertPreConditions {
    my $self = shift;
    my $var = shift;
    my $status1 = $var->[0];
    
    my @bits = CommonRoutines::breakIntegerToBinaryArray($status1);
    if ($bits[-3]) {
        return 0; #this item has already been deleted, so lets not insert it.
    }
    else {
        return 1;
    }
}