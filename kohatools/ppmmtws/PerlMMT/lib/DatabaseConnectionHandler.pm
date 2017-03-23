package DatabaseConnectionHandler;

use strict;
use warnings;
use DBI;
use utf8;

=synopsis
It automates connecting and closing database connections straight from MasterMigrationTool config.pl.

@param1, $self when called using ->
@param2, (OPTIONAL) $configHashReference parsed from the config.xml file in the root of mmt-project. Otherwise using the $CFG::CFG->

=cut
sub getConnection {
    my $self = shift;
    my $configHashRef = shift;
    my $config;
    
    if (defined $configHashRef && ref $configHashRef eq "HASH") {
        $config = $configHashRef->{Databases}->{Evergreen};
    }
    else {
        $config = $CFG::CFG->{Databases}->{Evergreen};
    }
    
    

    return executeGetConnection($config);
}
sub getRepositoryConnection {
    my $param = {@_};
    
    my $config = $CFG::CFG->{Databases}->{Repositories};

    return executeGetConnection($config);
}
sub executeGetConnection {
    my $correctConfig = shift;

    my $dbname = $correctConfig->{'DatabaseName'};
    my $hostname = $correctConfig->{'Hostname'};
    my $port = $correctConfig->{'Port'};
    my $password = $correctConfig->{'Password'};
    my $username = $correctConfig->{'Username'};
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$hostname;port=$port", $username, $password, {PrintError => 1});

    return $dbh;
}

"suck this Perl!";