package MMT::FinesMigrator;

use Modern::Perl;

use MMT::Util::Common;
use MMT::Util::CSVStreamer;
use MMT::Objects::Fine;

my $startTime = time();

=head FinesMigrator

=head SYNOPSIS

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    bless $self, $class;

    my $config = $CFG::CFG;

    $self->{verbose} = 0 unless $params->{verbose} || $config->{verbose};
    $self->{_config} = $config;

    return $self;
}

sub run {
    my ($self) = @_;

    print "\n\n".MMT::Util::Common::printTime($startTime)." FinesMigrator - Starting\n\n";

    open(my $objOut, ">:encoding(utf8)", $CFG::CFG->{targetDataDirectory}."Maksu.migrateme") or die "$!";
    my $csvStreamer = MMT::Util::CSVStreamer->new($CFG::CFG->{origoValidatedBaseDir}."Maksu.csv",
                                                  '<');

    while (my $row = $csvStreamer->next()) {
        print MMT::Util::Common::printTime($startTime)." FinesMigrator - ".($csvStreamer->{i}+1)."\n" if $csvStreamer->{i} % 1000 == 999;
        my $object = MMT::Objects::Fine->constructor($self, $row);
        next unless $object;

        print $objOut $object->toString()."\n";
        $object->DESTROY(); #Prevent memory leaking.
    }
    $csvStreamer->close();
    close($objOut);

    print "\n\n".MMT::Util::Common::printTime($startTime)." FinesMigrator - Complete\n\n";
}

1;
