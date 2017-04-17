package MMT::Repository::MarcRepository;

use Modern::Perl;
use threads;
use threads::shared;

use MMT::Repository::ArrayRepository;

use base qw(MMT::Repository::ArrayRepository);

my $filename = "TranslationTables/MarcRepository.csv";
sub createRepository {
    my ($class, $ioOp) = @_;
    return $class->SUPER::createRepository({filename => $filename, ioOp => $ioOp});
}

#my $prepareDataLock :shared = 1;
sub prepareData {
    #lock $prepareDataLock;
    my ($self, $r) = @_;

    my $pk = $r->docId;

    my $signum = $r->signum();
    my $materialType = $r->materialType();
    my $coded_location_qualifier = $r->{overrides}->{items}->{coded_location_qualifier};

    $signum = 'NO SIGNUM' if !(defined($signum));
    $materialType = 'NO ITYPE' if !(defined($materialType));
    $coded_location_qualifier = '' if !(defined($coded_location_qualifier)); #Possibly override items.coded_location_qualifier

    return [$pk, $signum, $materialType, $coded_location_qualifier];
}