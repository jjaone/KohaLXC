package ChunkDealer;

use warnings;
use strict;
#use diagnostics;

use threads;
use threads::shared;

sub new {
    my $class = $_[0];
    my $self = shared_clone {};
    bless($self, $class);
    
    $self->{fileName} = $_[1];
    $self->{startingChunk} = (defined $_[2]) ? $_[2] : 0;
    $self->{endingChunk} = (defined $_[3] && $_[3] >= 0) ? $_[3] : 9999;
    $self->{fetchLock} = 0;
    $self->{i} = 0;
    
    #Rewind the ChunkDealer to the starting position
    if ($self->{startingChunk} > 0) {
        while ($self->{i} < $self->{startingChunk}) {
            fetch($self);
        }
    }
    
    return shared_clone $self;
}

sub fetch {
    lock $_[0];
    my $self = shift;
    
    if ( $self->{i} >= $self->{endingChunk} ) {
        return (undef,undef);
    }
    
    my $suffix = sprintf("%04d", $self->{i});
    $self->{i} += 1;
    
    if (-e $self->{fileName}.$suffix) {
        return ($self->{fileName}.$suffix, $suffix);
    }
    
    return undef; #no more licmarca.kir-chunks to process
}

sub getLastChunk {
    my $self = shift;
    
    my $suffix;
    #Get the amount of fileName-chunks , unix-split splits chunks up until suffix *99
    for (my $i=0 ; $i<=9999 ; $i++) {
        my $newSuffix = sprintf("%04d", $i);
        if (! -e $self->{fileName}.$newSuffix) {
            return $self->{fileName}.$suffix #we have found the last of fileName-chunks
        }
        $suffix = $newSuffix;
    }
    return undef;
}

sub getBaseFileName {
    return $_[0]->{fileName};
}
1;