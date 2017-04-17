package MMT::PreProcessor;

use Modern::Perl;

use File::Basename;

use MMT::Util::Common;
use MMT::Util::CSVStreamer;
use MMT::PreProcessor::StreamParser;
use MMT::PreProcessor::Extractor;
use MMT::PreProcessor::Validator;
use TranslationTables::SourceValidationRules;

=head PreProcessor

=head SYNOPSIS

PreProcessor reads, parses, extracts, validates, encodes and converts the source
data files. This module makes sure the data is valid according to the given configuration
options.
Knowing your source data makes doing the migration much easier.

This module and it's submodules use the Tables::SourceValidationRules-package to get
rules for dealing with source data columns.

=cut

my $startTime = time();

sub run {
    my ($params) = @_;

    #$params->{filename} = 'Puhelin.txt';
    sourceDataValidation($params);
    usemarconConversion($params);

    print "\n\n".MMT::Util::Common::printTime($startTime)." PreProcessor - Complete\n\n";
}

sub writeToDisk {
    my ($self, $filename, $rows) = @_;

    my ($name,$path,$suffix) = File::Basename::fileparse($filename, ('.txt'));
    my $csvStreamer = MMT::Util::CSVStreamer->new( $self->config->{origoValidatedBaseDir}.$name.'.csv',
                                                   '>' );
    foreach my $row (@$rows) {
        my @mergedAry;
        foreach my $subRow (@$row) {
            push(@mergedAry, @$subRow);
        }
        $csvStreamer->put(\@mergedAry);
    }
    $csvStreamer->close();
}

sub sourceDataValidation {
    my ($params) = @_;

    my $config = $CFG::CFG;
    my $svr = TranslationTables::SourceValidationRules::get();
    my $svr_config = $svr->{_config};
    map {$svr_config->{$_} = $config->{$_}} keys %$config;
    map {$svr_config->{$_} = $params->{$_}} keys %$params if $params;

    my $sp = MMT::PreProcessor::StreamParser->new($svr_config);
    my $ex = MMT::PreProcessor::Extractor->new($params);
    my $va = MMT::PreProcessor::Validator->new($params);

    foreach my $filename (sort keys %$svr) {
        next unless $filename =~ m/.txt$/; #Skip config parameters etc.
        next if $params->{filename} && not($filename eq $params->{filename}); #We might want to only test single files

        print "\n\n".MMT::Util::Common::printTime($startTime)." PreProcessor - Starting   file '$filename'\n\n";
        print "----".MMT::Util::Common::printTime($startTime)." PreProcessor - Parsing    file '$filename'\n";
        my $rows = $sp->parse_file($filename);
        print "----".MMT::Util::Common::printTime($startTime)." PreProcessor - Extracting file '$filename'\n";
        $rows = $ex->extract($filename, $rows);
        print "----".MMT::Util::Common::printTime($startTime)." PreProcessor - Validating file '$filename'\n";
        $rows = $va->validate($filename, $rows);
        print "----".MMT::Util::Common::printTime($startTime)." PreProcessor - Writing    file '$filename' as .csv\n";
        writeToDisk($sp, $filename, $rows);
    }
}

sub usemarconConversion {
    my ($params) = @_;

    my $config = $CFG::CFG;
    print "\n\n".MMT::Util::Common::printTime($startTime)."PreProcessor - Usemarcon conversion\n";

    my $cmd = "Usemarcon/usemarcon -v Usemarcon/fi2ma/fi2ma.ini ".              #Verbose output with the rulefile
               $config->{origoSourceBaseDir}.$config->{Biblios}->{FinMARCsource}.#Source file
               " ".
               $config->{origoValidatedBaseDir}.$config->{Biblios}->{UsemarconTarget}.#Destination file
               " |";                                                            #Pipe it to this script.

    my $stringBuilder = MMT::Util::Common::executeShell($cmd, 'realtimePrinting');

    print "----".MMT::Util::Common::printTime($startTime)."PreProcessor - Usemarcon conversion complete\n";
}

1;
