#!/usr/bin/perl

use Asiasanat;
#use Data::Dumper;

my $sanat = Asiasanat->new();

$sanat->init();

$sanat->download_default_files();
#$sanat->download_file($url, "file.rdf");
$sanat->process_downloaded_files();

#$Data::Dumper::Indent = 1;
#$Data::Dumper::Sortkeys = 1;
#print Dumper($sanat->{'lang'});
#exit;

print $sanat->normalize_keyword()."\n";

print $sanat->normalize_keyword("TULLI LAITOS"). "\n";
print $sanat->normalize_keyword("dokumenttiromaanit"). "\n";
print $sanat->normalize_keyword("puutarha-arkkitehtuuri"). "\n";
print $sanat->normalize_keyword("gardenart"). "\n";
print $sanat->normalize_keyword("garden art"). "\n";
print $sanat->normalize_keyword("trädgårdskonst"). "\n";
print $sanat->normalize_keyword("trädgårdsarkitektur"). "\n";
print $sanat->normalize_keyword("SPEED way"). "\n";

sub read_data_file {
    my $fname = shift;
    my @dat;
    my $l;
    open(INPUT, $fname) or die "could not open $fname: $!";
    foreach $l (<INPUT>) {
        $l =~ s/^\s+//;
        $l =~ s/\s+$//;
        push(@dat, $l);
    }
    close(INPUT);
    return @dat;
}


my @data = read_data_file("asiasanat_650a_uniq.txt");
foreach my $l (@data) {
    print "UNKNOWN: ".$l."\n" if ($sanat->is_unknown_keyword($l));
#    print $l ." == " . $sanat->normalize_keyword($l) . "\n";
}
