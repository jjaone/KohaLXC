#!/usr/bin/perl

use strict;
use warnings;

use open qw( :std :encoding(UTF-8) );
binmode( STDOUT, ":encoding(UTF-8)" );

use Getopt::Long;


my $starting_biblionumber = 1;
my $starting_itemnumber = 1;
my $starting_borrowernumber = 1;

my $kohamigrationpath = '/home/koha/kohamigration/';
my $bibliosfile = $kohamigrationpath.'biblios.migrateme';
my $itemsfile =   $kohamigrationpath.'items.migrateme';
my $patronsfile = $kohamigrationpath.'patrons.migrateme';

my $keysfolder = '/home/koha/kohamigration/keys_translated/';


my $fh_biblios = IO::File->new($bibliosfile, 'r');
my $fh_items = IO::File->new($itemsfile, 'r');
my $fh_patrons = IO::File->new($patronsfile, 'r');
my $fh_bibkeys = IO::File->new($keysfolder.'keys.docid_biblionumber', 'w');
my $fh_itmkeys = IO::File->new($keysfolder.'keys.copyid_itemnumber', 'w');
my $fh_patkeys = IO::File->new($keysfolder.'keys.custid_borrowernumber', 'w');





my @keys;

my $i = $starting_biblionumber;
while (<$fh_biblios>) {
    if ($_ =~ '<controlfield tag="001">(\d+)</controlfield>') {
        push @keys, "$1\t$i";
        $i++;
    }
}

print $fh_bibkeys join("\n", @keys);
@keys = undef;
$fh_bibkeys->close();
$fh_biblios->close();


$i = $starting_itemnumber;
while (<$fh_items>) {
    if ($_ =~ /,'id' => '(\d+)',/) {
        push @keys, "$1\t$i";
        $i++;
    }
}

print $fh_itmkeys join("\n", @keys);
@keys = undef;
$fh_itmkeys->close();
$fh_items->close();


$i = $starting_borrowernumber;
while (<$fh_patrons>) {
    if ($_ =~ /,'borrowernumber' => '(\d+)',/) {
        push @keys, "$1\t$i";
        $i++;
    }
}

print $fh_patkeys join("\n", @keys);
@keys = undef;
$fh_patkeys->close();
$fh_patrons->close();