package MMT::Objects::BaseObject;

use Modern::Perl;

$Data::Dumper::Indent = 0;
$Data::Dumper::Purity = 1;

sub constructor {
    die "\nMMT::Objects::BaseObject CONSTRUCTOR MUST BE OVERLOADED\n";
}

sub DESTROY {
    my $self = shift;

    foreach my $k (keys %$self) {

        undef $self->{$k};
        delete $self->{$k};
    }
}

sub toString {
    my $p = shift;

    my $sb = ['$VAR1 = bless( '];

    _toStringRecursion($p, $sb);

    push (@$sb, " 'Item' );");

    return join('',@$sb);
}

sub _toStringRecursion {
    my ($p, $sb) = @_;

    push(@$sb, '{');
    for my $key (sort keys %$p) {
        if (exists $p->{$key}) {
            my $value = $p->{$key};

            if (ref $value eq 'HASH') {
                push(@$sb, "'$key' => ");
                _toStringRecursion($value, $sb);
            }
            else {
                print "Undefined: $key\n" unless(defined($p->{$key}));
                $p->{$key} =~ s/'/\\'/g; #Sanitate quotation marks
                $p->{$key} = Encode::decode_utf8($p->{$key}); # set the flag

                push( @$sb, "'$key' => '$p->{$key}', " );
            }
        }
        else {
            warn 'Item with barcode '.$p->{barcode}.': Has a key '.$key.' with no value?!';
        }
    }
    push(@$sb, '}, ');
}

sub _addNote {
    my ($self, $note) = @_;
    my $noteColumn;
    if (ref($self) =~ /Borrower/) {
        $noteColumn = 'contactnote';
    }
    elsif (ref($self) =~ /Item/) {
        $noteColumn = 'itemnotes';
    }
    elsif (ref($self) =~ /Hold/) {
        $noteColumn = 'reservenotes';
    }
    else {
        die "BaseObject::_addNote():> Unknown Object reference '".ref($self)."'. Add package detectors here to autodetect the correct notification column!\n";
    }

    if ($self->{$noteColumn}) {
        $self->{$noteColumn} .= ' ][ '.$note;
    }
    else {
        $self->{$noteColumn} = $note;
    }
}

sub _dump {
    my ($self) = @_;
    return join(",",@{$self->{c}} );
}
sub _error {
    my ($self, $msg) = @_;
    my ($package, $filename, $line, $subroutine) = caller(1);
    $subroutine =~ s/${package}:://;
    $package =~ s/MMT::Objects:://;
    return "$package->$subroutine():> $msg. Item '".$self->_dump()."'\n";
}
sub _errorNoDump {
    my ($self, $msg) = @_;
    my ($package, $filename, $line, $subroutine) = caller(1);
    $subroutine =~ s/${package}:://;
    $package =~ s/MMT::Objects:://;
    return "$package->$subroutine():> $msg\n";
}
sub _errorPk {
    my ($self, $msg) = @_;
    my $pkColumn;
    if (ref($self) =~ /Borrower/) {
        $pkColumn = 'borrowernumber';
    }
    elsif (ref($self) =~ /Item/) {
        $pkColumn = 'itemnumber';
    }
    elsif (ref($self) =~ /Hold/) {
        $pkColumn = 'borrowernumber';
    }
    elsif (ref($self) =~ /Checkout/) {
        $pkColumn = 'borrowernumber';
    }
    elsif (ref($self) =~ /Fine/) {
        $pkColumn = 'borrowernumber';
    }
    else {
        die "BaseObject::_errorPk():> Unknown Object reference '".ref($self)."'. Add package detectors here to autodetect the correct primary key column!\n";
    }
    my ($package, $filename, $line, $subroutine) = caller(1);
    $subroutine =~ s/${package}:://;
    $package =~ s/MMT::Objects:://;
    return "$package->$subroutine():> Object '".$self->{$pkColumn}."'. $msg\n";
}

sub _KohalizeDate {
    my ($self, $date) = @_;
    if ($date =~ /^1900-01-01 00:00:00/) {
        return undef;
    }
    return $date;
}

1;
