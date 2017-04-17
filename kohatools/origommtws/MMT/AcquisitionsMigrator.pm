package MMT::AcquisitionsMigrator;

use Modern::Perl;

use YAML::XS;

use MMT::Repository::AuthoritiesRepository;
use MMT::Util::Common;
use MMT::Util::CSVStreamer;
use MMT::Objects::Item;

my $startTime = time();

=head AcquisitionsMigrator

=head SYNOPSIS

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    bless $self, $class;

    my $config = $CFG::CFG;

    $self->{verbose} = 0 unless $params->{verbose} || $config->{verbose};
    $self->{_config} = $config;

    $self->{repositories}->{MarcRepository} = MMT::Repository::MarcRepository->createRepository('<'); #Open the repo for reading

    return $self;
}

sub run {
    my ($self) = @_;

    print "\n\n".MMT::Util::Common::printTime($startTime)." AcquisitionsMigrator - Starting\n\n";

    open(my $objOut, ">:encoding(utf8)", $CFG::CFG->{targetDataDirectory}."Hankinta.migrateme") or die "$!";
    my $csvStreamer = MMT::Util::CSVStreamer->new($CFG::CFG->{origoValidatedBaseDir}."Hankinta.csv",
                                                  '<');

    while (my $row = $csvStreamer->next()) {
        my $itemsCount = $row->[6]; #7 Lukumaara
        foreach my $i (1..$itemsCount) {
            print MMT::Util::Common::printTime($startTime)." AcquisitionsMigrator - ".($csvStreamer->{i}+1)."\n" if $csvStreamer->{i} % 1000 == 999;
            my $object = MMT::Objects::Item->acquisitionConstructor($self, $row);
            next unless $object;

            print $objOut $object->toString()."\n";
            $object->DESTROY(); #Prevent memory leaking.
        }
    }
    $csvStreamer->close();
    close($objOut);

    print "\n\n".MMT::Util::Common::printTime($startTime)." AcquisitionsMigrator - Complete\n\n";
}

1;
