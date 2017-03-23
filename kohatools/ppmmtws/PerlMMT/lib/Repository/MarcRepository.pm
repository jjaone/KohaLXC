package Repository::MarcRepository;

use warnings;
use strict;
use utf8;
use threads;
use threads::shared;
    
use CommonRoutines;

#This is to prevent row misalignment when writing
my $writeAuthorityLock :shared = 1;

sub createRepository {
    
    #lets time the duration taken
    my $startTime = time();
    
    my $class = shift;
    my $self = {@_};
    if(! exists($self->{'filePath'})) {
        warn "MarcRepository filePath not defined.";
        return undef;
    }
    if(! exists($self->{'logger'})) {
        warn "MarcRepository logger not defined.";
        return undef;
    }

    $self->{'fileBasename'} = File::Basename::basename($self->{'filePath'});

    print "\nMarcRepository on  ",$self->{'filePath'};
    
    bless($self, $class);

    $self->loadFromPregeneratedFile();
    #$self->loadFromPregeneratedFile();
    
    print "\nTime taken " . (time() - $startTime) . "seconds \n";
    
    return $self;
}

sub createFileFromMARC_Records {
    my $records = shift;
    my $targetFileHandle = shift;
    
    foreach my $key (sort keys %$records) {
        my $r = $records->{$key};
        
        my $pk = $r->docId;
        if ($pk == 10036644) {
            my $break = 1;
        }
        my $subfield041a = $r->getUnrepeatableSubfield('041','a');
        my $language = (defined $subfield041a) ? $subfield041a->content() : 'fin';
        
        my $signum = $r->signum();
        my $pallasMaterialCode = $r->materialType();
        my $countryOfOrigin = $r->countryOfOrigin(); #This is not used anywhere, this was originally thought of as the language
        
        my $price = $r->getUnrepeatableSubfield('021','d');
        $price = (defined $price) ? $price->content() : '0';
        
        my $f300z = $r->getUnrepeatableSubfield('300', 'z');
        $f300z = (defined $f300z) ? $f300z->content() : '';
        
        my $f300d = $r->getUnrepeatableSubfield('300', 'd');
        $f300d = (defined $f300d) ? $f300d->content() : '';
        
        my $callNumbers = '';
        my $f852s = $r->fields('852');
        if (defined $f852s) {
            foreach my $f (@{$f852s}) {
                $callNumbers .= $f->contentToText();
            }
        }

        #if (!$signum || !$pk || !$pallasMaterialCode || !$language || !$callNumbers) {
        #	print 'dikker';
        #}
        
        $signum = 'NO SIGNUM' if !(defined($signum));
        $pallasMaterialCode = 'NO PP MAT.CODE' if !(defined($pallasMaterialCode));
        $countryOfOrigin = 'NO COUNTRY_OF_ORIGIN' if !(defined($countryOfOrigin));
                
        my $output = join("\t", ($pk,$signum,$price,$pallasMaterialCode,$countryOfOrigin,$language,$f300z,$f300d,$callNumbers) );
        #$targetFileHandle->print( $output."\n" );
        lock $writeAuthorityLock;
        print $targetFileHandle $output."\n";
    }
}

sub loadFromPregeneratedFile {
    my $self = shift;
    my $DEBUGAuthCountLimit = $CFG::CFG->{'DEBUGAuthoritiesCountLimit'}; #Limits how many authorities are loaded, use something <=0 to load the whole repo
    my %columns;

    #print $self->{'filePath'};
    
    open LICMARCA, "<:utf8", $self->{'filePath'} or die $!;
    
    my $authCount = 0; #Counts how many authorities have been loaded
    while (<LICMARCA>) {
        
        #get pallaslabel, signum
        
        #get price from 021
        
        #get locations
        my @row = split "\t", $_;
        pop @row; #remove the last index, which is a newline
        
        if ( $DEBUGAuthCountLimit > 0 && $authCount++ > $DEBUGAuthCountLimit ) {
            last();
        }
        
        my %content;
        
        my $pk = shift @row;
        $content{signum} = shift @row;
        $content{price} = shift @row;
        $content{pallasMaterialCode} = shift @row;
        $content{countryOfOrigin} = shift @row;
        $content{language} = shift @row;
        $content{f300z} = shift @row;
        $content{f300d} = shift @row;
        
        if ($pk == 10036644) {
            my $break = 1;
        }
                
        #extract call number ISIL location code pairs
        for ( my $i=0 ; $i < scalar(@row) ; $i+=2 ) {
            my $isil = $row[$i];
            my $callNumber = $row[$i+1];
            if ( ! exists($content{$isil}) ) {
                $content{$isil} = $callNumber;
            }
        }

        $columns{$pk} = \%content;
    }
    
    close(LICMARCA);
    
    $self->{'data'} = \%columns;
}

#fetches a designated key from one authority record, or the whole stored authority record.
sub fetch {
    #lock $_[0]->[$_[1]];
    my $self = $_[0];
    my $pk = $_[1];
    my $key = $_[2] if $_[2];
    
    if ($key) {
        my $retval = $self->{data}->{$pk}->{$key};
            if (! defined $retval) {
                #$self->{logger}->warn('No authority for pk = '.$pk.', key = '.$key);
                return undef;
            }
        return $retval;
    }
    else {
        return $self->{data}->{$pk};
    }
}

sub fetchAllIsil {
    my $self = $_[0];
    my $pk = $_[1];
    
    my $isil = [];
    for my $key (keys %{$self->{data}->{$pk}}) {
    push @$isil, $key if $key =~ m/\w\w-\w+/;
    }
    return $isil;
}	  

#return true to make compiler happy!
1;
