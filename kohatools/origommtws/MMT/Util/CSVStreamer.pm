package MMT::Util::CSVStreamer;

use Modern::Perl;

sub new {
    my ($class, $filename, $ioOp) = @_;
    my $s = {};
    bless($s, $class);

    my $callingPackage = _figureCallingClass();
    my $config = ($callingPackage) ? $CFG::CFG->{$callingPackage} : {};
    $s->{config} = $config;

    my $eol = "\n" if ($ioOp eq '>');
    $s->{csv} = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
    $s->{csv}->eol($eol) if $eol;
    open my $fh, "$ioOp:encoding(utf8)", $filename or die __PACKAGE__."->new():> Couldn't open filename '$filename' for operation '$ioOp': '$!'\n";
    $s->{fh} = $fh;

    $s->{i} = 0;
    $s->{count} = 0;

    return $s;
}

sub close {
    my ($s) = @_;
    my $fh = $s->{fh};
    close $fh;
}

sub next {
    my ($s) = @_;
    my $fh = $s->{fh};
    $s->{i}++;
    $s->{count}++;

    return undef if ($s->{config}->{count} && $s->{config}->{count} >= $s->{count});
    my $row = $s->{csv}->getline($fh);
    return $row;
}

sub put {
    my ($s, $columns) = @_;
    my $fh = $s->{fh};
    $s->{i}++;
    $s->{count}++;

    my $ok = $s->{csv}->print($fh, $columns);
    return $ok;
}

sub _figureCallingClass {
    my ($recurseDepth) = @_;
    $recurseDepth = 1 unless $recurseDepth;

    my ($package, $filename, $line) = caller($recurseDepth);
    if ($package =~ /MMT::(\w+)Migrator$/) {
        return $1;
    }
    elsif ($package =~ /TranslationTables/ || $package =~ /PreProcessor/) {
        return undef;
    }
    else {
        if ($recurseDepth < 15) {
            return _figureCallingClass($recurseDepth+2);
        }
        die __PACKAGE__."->_figureCallingClass():> Couldn't autodetect the calling migration chain from package '$package'!!\nThis can only be called from packages with name BibliosMigrator, ItemsMigrator, *Migrator.\nPackage name is used to detect correct configuration settings from the master config file.\n";
    }
}

sub _rewindSkipSteps {
    my ($s) = @_;

    if ($s->{config}->{skip}) {
        my $fh = $s->{fh};
        while ($s->{i} < $s->{config}->{skip}) {
            $s->{i}++; #rewind the skip steps
            my $row = $s->{csv}->getline($fh);
        }
    }
}

1;
