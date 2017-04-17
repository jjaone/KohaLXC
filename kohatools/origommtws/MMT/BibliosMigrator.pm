package MMT::BibliosMigrator;

use Modern::Perl;
use threads;
use threads::shared;

use YAML::XS;

use MMT::Repository::AuthoritiesRepository;
use MMT::Repository::MarcRepository;
use MMT::Biblios::MarcRepair;
use MMT::Util::MARCXMLReader;
use MMT::Util::Common;
use MMT::MARC::Printer;


my %available001andPublicationDate; #Collect available component parent ID's here so we can verify that 773$w points somewhere.
my %linking773w; #Collect component part record id's and their parent references here.
my $startTime = time();
my $threads = [];

=head BibliosMigrator

=head SYNOPSIS

Merges data outside the MARC record to the MARC record. Validates link relations.
Extracts markers needed for Items migration.

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    bless $self, $class;

    my $config = $CFG::CFG;

    $self->{verbose} = 0 unless $params->{verbose} || $config->{verbose};
    $self->{_config} = $config;

    $self->{repositories}->{Teos} = MMT::Repository::ArrayRepository->createRepository({filename => $CFG::CFG->{origoValidatedBaseDir}.'/Teos.csv', ioOp => '<', pkColumn => 0});
    $self->{repositories}->{Nide} = MMT::Repository::ArrayRepository->createRepository({filename => $CFG::CFG->{origoValidatedBaseDir}.'/Nide.csv', ioOp => '<', pkColumn => 2, columns => [16]});
    $self->{repositories}->{MarcRepository} = MMT::Repository::MarcRepository->createRepository('>'); #Open the repo for writing
    $self->{marcxmlReader} = MMT::Util::MARCXMLReader->new({sourceFile => $self->{_config}->{origoValidatedBaseDir}.
                                                                          $self->{_config}->{Biblios}->{UsemarconTarget}
                                                        });

    return $self;
}

sub run {
    my ($self) = @_;

    print "\n\n".MMT::Util::Common::printTime($startTime)." BibliosMigrator - Starting\n\n";
    MMT::MARC::Printer::startCollection();

    my $i :shared = 0;
    my $count :shared = 0;
    my $threadRoutine = sub {
        my $self = shift;
        $self->{threadId} = shift().'' || 1;
        while (my $record = $self->nextXML()) {
            $i++;
            next if ($CFG::CFG->{Biblios}->{skip} && $CFG::CFG->{Biblios}->{skip} >= $i);
            last if ($CFG::CFG->{Biblios}->{count} && $CFG::CFG->{Biblios}->{count} >= $count);

            print MMT::Util::Common::printTime($startTime)." BibliosMigrator - (".$self->{threadId}.") ".($i+1)."\n" if $i % 1000 == 999;

            #Fetch data from a possible component parent.
            getParentPublicationDate($record);

            next() unless ($self->handleRecord($i, $record));
            next() unless (MMT::Biblios::MarcRepair::run($self, $record));
            MMT::MARC::Printer::writeRecord($record);
            $self->{repositories}->{MarcRepository}->put($record);

            saveRecord($record);

            $record->DESTROY(); #Prevent memory leaking.
            $count++;
        }
    };
    ### Threaded programming starts HERE ###
    #Initialize threads
    if ($CFG::CFG->{threadCount} > 1) {
		for my $i (1..$CFG::CFG->{threadCount}) {
			$threads->[$i] = threads->create( $threadRoutine,$self,$i );
		}
        #Keep monitoring thread status
		while (@$threads > 0) {
			for (my $ti=0 ; $ti<@$threads ; $ti++) {
				my $thread = $threads->[$ti];
				# Check thread's state
			    if ($thread->is_running()) {
				    sleep(5);
			    }
			    if ($thread->is_joinable()) {
				    $thread->join();
				    splice @$threads, $ti, 1;
			    }
		    }
		}
    } ##EO Threaded programming
    ### Synchronous programming HERE ###
    else {
	&$threadRoutine($self, $CFG::CFG->{threadCount});
    }## EO Synhronous programming

    
    MMT::MARC::Printer::endCollection();

    $self->validateLinkRelations();
    MMT::Biblios::MarcRepair::printStatistics();
    print "\n\n".MMT::Util::Common::printTime($startTime)." BibliosMigrator - Complete\n";
    print "Remember to fix component part link (773w->001 && 003->003)- and publication date (in 008) relations from the component parent!\n\n";
}

#my $getXmlLock :shared = 1;
sub nextXML {
#    lock $getXmlLock;
    my ($self) = @_;

    return $self->{marcxmlReader}->next();
}

sub handleRecord {
    my ($self, $i, $record) = @_;

    my $id = $record->docId();
    unless ($id) {
        warn "No Field 001 for Record number $i\n";
        return undef;
    }

    eval {
        my $teosRow = $self->{repositories}->{Teos}->fetch($id);
        if ($teosRow) {
            my $lastModificationDate = $teosRow->[2];
            my $addDate = $teosRow->[5];
            my $itemType = $teosRow->[1];

            $record->materialType($itemType);
            $record->dateReceived($addDate);
            $record->modTime($lastModificationDate);
        }
        else {
            print "Missing Teos-authority for Record '".$record->docId()."'\n";
        }
    };
    if ($@) {
        if ($@ =~ /DELETE/) {
            return undef;
        }
        else {
            die $@;
        }
    }
    return 1;
}

=getParentPublicationDate
Get the missing parent publication date from a possible component part.
=cut
sub getParentPublicationDate {
    my ($record) = @_;

    my $publicationDate = $available001andPublicationDate{ $record->getComponentParentDocid() };
    $record->publicationDate($publicationDate) if (not($record->publicationDate()) && $publicationDate);
}

sub saveRecord {
    my ($record) = @_;

    #Save Record's ID and possible linking targets, so we can validate them.
    my $id = $record->docId();
    my $publicationDate = $record->publicationDate();
    $available001andPublicationDate{$id} = $publicationDate;
    if (my $cParentId = $record->getComponentParentDocid()) {
        $linking773w{$id} = $cParentId;
    }
}

sub validateLinkRelations {
    my ($self) = @_;

    print "\n\n".MMT::Util::Common::printTime($startTime)." BibliosMigrator - Validating link relations\n\n";
    while (my ($componentPartId, $componentParentId) = each(%linking773w)) {
        unless($available001andPublicationDate{$componentParentId}) {
            print "Component part '$componentPartId' doesn't have a component parent!\n"
        }
    }
}

1;
