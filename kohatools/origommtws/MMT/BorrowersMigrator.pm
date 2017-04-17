package MMT::BorrowersMigrator;

use Modern::Perl;

use YAML::XS;

use MMT::Repository::AuthoritiesRepository;
use MMT::Repository::ArrayRepository;
use MMT::Util::Common;
use MMT::Util::CSVStreamer;
use MMT::Objects::Borrower;

my $startTime = time();

=head BorrowersMigrator

=head SYNOPSIS

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    bless $self, $class;

    my $config = $CFG::CFG;

    $self->{verbose} = 0 unless $params->{verbose} || $config->{verbose};
    $self->{_config} = $config;

    $self->{repositories}->{Asiakasviivakoodi} = MMT::Repository::ArrayRepository->createRepository({filename => $config->{origoValidatedBaseDir}.'Asiakasviivakoodi.csv', ioOp => '<', pkColumn => 1});
    $self->{repositories}->{KontaktiID_to_AsiakasID} = MMT::Repository::ArrayRepository->createRepository({filename => $config->{origoValidatedBaseDir}.'Asiakas.csv', ioOp => '<', pkColumn => 28, columns => [0]});
    $self->{repositories}->{Osoite} = MMT::Repository::ArrayRepository->createRepository({filename => $config->{origoValidatedBaseDir}.'Osoite.csv', ioOp => '<', pkColumn => 1});
    $self->{repositories}->{Puhelin} = MMT::Repository::ArrayRepository->createRepository({filename => $config->{origoValidatedBaseDir}.'Puhelin.csv', ioOp => '<', pkColumn => 1});
    $self->{repositories}->{Lainauskielto} = MMT::Repository::ArrayRepository->createRepository({filename => $config->{origoValidatedBaseDir}.'Lainauskielto.csv', ioOp => '<', pkColumn => 1});
    $self->{repositories}->{TakaajaID} = MMT::Repository::ArrayRepository->createRepository({filename => $config->{origoValidatedBaseDir}.'Asiakas.csv', ioOp => '<', pkColumn => 16, columns => [0]});

    return $self;
}

sub run {
    my ($self) = @_;

    print "\n\n".MMT::Util::Common::printTime($startTime)." BorrowersMigrator - Starting\n\n";

    open(my $objOut, ">:encoding(utf8)", $CFG::CFG->{targetDataDirectory}."Asiakas.migrateme") or die "$!";
    my $csvStreamer = MMT::Util::CSVStreamer->new($CFG::CFG->{origoValidatedBaseDir}."Asiakas.csv",
                                                  '<');

    while (my $row = $csvStreamer->next()) {
        print MMT::Util::Common::printTime($startTime)." BorrowersMigrator - ".($csvStreamer->{i}+1)."\n" if $csvStreamer->{i} % 1000 == 999;
        my $object = MMT::Objects::Borrower->constructor($self, $row);
        next unless $object;

        print $objOut $object->toString()."\n";
        $object->DESTROY(); #Prevent memory leaking.
    }
    $csvStreamer->close();
    close($objOut);

    print "\n\n".MMT::Util::Common::printTime($startTime)." BorrowersMigrator - Complete\n\n";
}

1;
