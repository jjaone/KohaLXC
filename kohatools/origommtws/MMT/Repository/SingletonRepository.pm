package Repository::SingletonRepository;

use warnings;
use strict;
use utf8;
    
use CommonRoutines;


#Object constructor
sub createRepository {
	
	#lets time the duration taken
	my $startTime = time();
	
	my $class = shift;
	my $self = {@_};
    my $errorsInConfig = 0;
	if(! exists($self->{'filePath'})) {
		warn "SingletonRepository filePath not defined.";
        $errorsInConfig++;
	}
	if(! exists($self->{'pk'})) {
		warn "SingletonRepository pk(primary key) not defined.";
		$errorsInConfig++;
	}
	#if(! exists($self->{'columns'}) || ref $self->{'columns'} ne 'ARRAY') {
	#	warn "SingletonRepository columns not defined or not an array.";
	#	$errorsInConfig++;
	#}
    if(! exists($self->{'logger'})) {
		warn "SingletonRepository logger configuration package not defined.";
		$errorsInConfig++;
	}
    if ($errorsInConfig) {
        return undef;
    }

	$self->{'fileBasename'} = File::Basename::basename($self->{'filePath'});

	$self->{logger} = LiteLogger->new({ package => $self->{logger} });

	$self->{logger}->info("Initing on file ".$self->{'filePath'});
	
	bless($self, $class);
    
	$self->loadFile();
	
	$self->{logger}->info("Time taken " . (time() - $startTime) . "seconds");
	
	return $self;
}


sub loadFile {
	my $self = shift;
	my $DEBUGAuthCountLimit = $CFG::CFG->{'DEBUGAuthoritiesCountLimit'}; #Limits how many authorities are loaded, use something <=0 to load the whole repo
	
	open LICAUTH, "<:utf8", $self->{'filePath'} or die $!;
	
	my $authCount = 0; #Counts how many authorities have been loaded
	while (<LICAUTH>) {
        next() if length $_ < 3;
        
        if ( $DEBUGAuthCountLimit > 0 && $authCount++ > $DEBUGAuthCountLimit ) {
			last();
		}
        
		my @row = split "\t", $_;
        my $pk = $row[$self->{'pk'}];

        ##as this is a singletonRepository, we save only the pk, the columns exist only to provide content for checkInsertPreConditions()
        if (exists $self->{columns}) {
            my @content;
            #get the number of columns to be extracted
            my $cols = $self->{'columns'};
            
            #extract the marc subfield code to $key and the content to $val
            for(my $i=0 ; $i<@$cols ; $i++) {
                my $val = $row[ $cols->[$i] ];
                push @content, $val;
            }
            
            if ($self->checkInsertPreConditions(\@content)) {
                $self->{'data'}->{$pk} = undef;
            }
        }
        else {
            $self->{'data'}->{$pk} = undef;
        }
		$authCount++;
	}
	
	close(LICAUTH);

}

sub checkInsertPreConditions {
	#override this!
	#var0 = object reference
	#var1 = $vars, requested column contents as array
    return 1;
}

sub fetch {
    #lock $_[0]->[$_[1]];
    my $self = shift;
    my $pk = shift;

	return (exists $self->{data}->{$pk}) ? 1 : 0 ;
}

#return true to make compiler happy!
1;