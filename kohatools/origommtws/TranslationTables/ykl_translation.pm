package TranslationTables::ykl_translation;

use Modern::Perl;

use MMT::Util::CSVStreamer;

my $isInit = 0;
our $kirkas = {};

sub translate {
    my ($code) = @_;

    init() unless $isInit;

    my $value = $kirkas->{$code} if defined($code);
    unless ($value) {
        print "Missing ykl class translation code '$code'\n";
        return;
    }
    return $value;
}

sub init {
    my $streamer = MMT::Util::CSVStreamer->new($CFG::CFG->{origoValidatedBaseDir}."AuktLuokka.csv",
                                               '<');
    while (my $row = $streamer->next()) {
        ##Build the ykl-code to ykl-value mapping table from the hundreds of source rows
        #ID        luokka    pitkänimi      luokka    paaluokkaID
        #100052	   6.2	     06.2 Museot    6.2	      100050

        $kirkas->{$row->[0]} = $row->[3];
    }
    $isInit++;
}

1;
