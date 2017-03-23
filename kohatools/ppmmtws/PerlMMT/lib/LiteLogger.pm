package LiteLogger;

use strict;
use warnings;
use utf8;

use Term::ANSIColor;

my $config = {
            'BibliosImportChain.PP_To_MARC' => {
                        'thread' => 0,
                        'noInfo' => 0,
            },
            'BibliosImportChain::Controller' => {
                        'thread' => 0,
                        'noInfo' => 1,
            },
            'BibliosImportChain::DatabaseWriter' => {
                        'thread' => 0,
            },
            'BibliosImportChain::FinMARC_Builder::BuildMARC' => {
                        'thread' => 0,
            },
            'BibliosImportChain::FinMARC_Builder' => {
                        'thread' => 0,
            },
            'PatronsImportChain::DatabaseWriter' => {
                        'thread' => 0,
            },
            'ItemsImportChain::DatabaseWriter' => {
                        'thread' => 0,
            },
            'ItemsImportChain::Controller' => {
                        'thread' => 0,
            },
            'ItemsImportChain::ItemsBuilder' => {
                        'thread' => 0,
            },
            'HoldsImportChain::Controller' => {
                        'thread' => 0,
            },
            'HoldsImportChain::HoldsBuilder' => {
                        'thread' => 0,
            },
            'Patron' => {
                        'thread' => 0,
            },
            'BibliosImportChain::MarcRepair' => {
                        'thread' => 0,
            },
            'CheckOutsImportChain::DatabaseWriter' => {
                        'thread' => 0,
            },
            'CheckOutsImportChain::Controller' => {
                        'thread' => 0,
            },
            'CheckOutsImportChain::Reader' => {
                        'thread' => 0,
            },
            'Checkout' => {
                        'thread' => 0,
            },
            'HistoryImportChain::Controller' => {
                        'thread' => 0,
            },
            'HistoryImportChain::Reader' => {
                        'thread' => 0,
            },
            'History' => {
                        'thread' => 0,
            },
            'DatabaseRepository::liccopy' => {
                        'thread' => 0,
            },
            'PatronsImportChain::huoltaja' => {
                        'thread' => 0,
            },
            'Fine' => {
                        'thread' => 0,
            },
            'ItemWriter' => {
                        'thread' => 0,
            },
            'DEFAULT' => {
                        'thread' => 0,
            },
};

sub new {
    my $class = shift;
    my $s = shift;
    my $package = $s->{package};
    $package = 'DEFAULT' unless $package;
    bless($s, $class);
    
    if (exists $config->{$package}->{file}) {
        open (IN, ">:utf8", $config->{$package}->{file});
        $s->{file} = \*IN;
    }
    $s->{thread} = $config->{$package}->{thread} if ( !($s->{thread}) );
    $s->{noInfo} = $config->{$package}->{noInfo};
    $s->{class} = $class;
    
    return $s;
}
sub info {
    return if defined $_[0]->{noInfo};
    print color 'green';
    shift->print_log(@_);
    print color 'reset';
}
sub error {
    print color 'red';
    shift->print_log(@_);
    print color 'reset';
}
sub warning {    
    print color 'yellow';
    shift->print_log(@_);
    print color 'reset';
}
sub print_log {
    my $s = shift;
    my $message = shift;
    $message = $s->{package}.'>> '.$message."\n";
    
    if (! (exists $s->{file})) {
        print $message;
        return();
    }
    
    my $toFileOrSTDOUTorBoth = shift;
    
    $toFileOrSTDOUTorBoth = (defined $toFileOrSTDOUTorBoth) ? $toFileOrSTDOUTorBoth : 's';
    
    my $file = $s->{file};

    print $message if $toFileOrSTDOUTorBoth =~ /s/i || $toFileOrSTDOUTorBoth =~ /b/i;
    print $file $message if $toFileOrSTDOUTorBoth =~ /f/i || $toFileOrSTDOUTorBoth =~ /b/i;
}

sub _DESTROY {
    my $s = shift;
    close $s->{file};
}

"dickursby";