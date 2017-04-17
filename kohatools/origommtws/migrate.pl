#!/usr/bin/perl

use Modern::Perl;

use Getopt::Long qw(:config no_ignore_case);

use MMT::PreProcessor;
use MMT::BibliosMigrator;
use MMT::ItemsMigrator;
use MMT::BorrowersMigrator;
use MMT::CheckoutsMigrator;
use MMT::FinesMigrator;
use MMT::HoldsMigrator;
use MMT::RotatingCollectionsMigrator;
use MMT::AcquisitionsMigrator;

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

my $help = 0;
my $verbose = 0;
my $migrateAll = 0;
my $preprocess = 0;
my $biblios = 0;
my $items = 0;
my $borrowers = 0;
my $checkouts = 0;
my $fines = 0;
my $holds = 0;
my $rotatingCollections = 0;
my $acquisitions = 0;

GetOptions(
            'h|help'         => \$help,
            'p|preprocess'   => \$preprocess,
            'b|biblios'      => \$biblios,
            'B|borrowers'    => \$borrowers,
            'i|items'        => \$items,
            'c|checkouts'    => \$checkouts,
            'v|verbose:i'    => \$verbose,
            'M|migrate-all'  => \$migrateAll,
            'f|fines'        => \$fines,
            'H|holds'        => \$holds,
            'r|rotating-collections' => \$rotatingCollections,
            'a|acquisitions' => \$acquisitions,
);

if ($help) {
    print <<HELP;
Help!
HELP
}


if ($migrateAll) {
    ($biblios, $items, $borrowers, $checkouts, $fines, $holds, $rotatingCollections, $acquisitions) = (1,1,1,1,1,1,1,1);
}


{
    my $CONFIGFILE = $ENV{OrigoMMTConfigFile} || 'config.yaml';
    package CFG;
    our $CFG = YAML::XS::LoadFile($CONFIGFILE);
}

##Firstly you should run the preprocessor to validate and transform data for easy digestion.
if ($preprocess) {
    #my $sp = MMT::PreProcessor::run({verbose => 3, filename => 'Nide.txt'});
    #my $sp = MMT::PreProcessor::run({verbose => 0, filename => 'AuktAsiakastyyppi.txt'});
    my $sp = MMT::PreProcessor::run({verbose => $verbose});
}
if ($biblios) {
    my $bm = MMT::BibliosMigrator->new({verbose => $verbose});
    $bm->run();
}
if ($items) {
    my $im = MMT::ItemsMigrator->new({verbose => $verbose});
    $im->run();
}
if ($borrowers) {
    my $bm = MMT::BorrowersMigrator->new({verbose => $verbose});
    $bm->run();
}
if ($checkouts) {
    my $cm = MMT::CheckoutsMigrator->new({verbose => $verbose});
    $cm->run();
}
if ($fines) {
    my $fm = MMT::FinesMigrator->new({verbose => $verbose});
    $fm->run();
}
if ($holds) {
    my $hm = MMT::HoldsMigrator->new({verbose => $verbose});
    $hm->run();
}
if ($rotatingCollections) {
    my $rm = MMT::RotatingCollectionsMigrator->new({verbose => $verbose});
    $rm->run();
}
if ($acquisitions) {
    my $am = MMT::AcquisitionsMigrator->new({verbose => $verbose});
    $am->run();
}
