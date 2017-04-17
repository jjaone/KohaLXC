package MMT::PreProcessor::Validator;

use Modern::Perl;

use TranslationTables::SourceValidationRules;

=head Validator

=head SYNOPSIS

Validator iterates the given rows and columns of a source data dump, and makes sure
the data in each column matches the configured source validation primitive type for the column.
Primitive types include 'int', 'string', 'datetime', 'boolean'...

If the given row fails validation, it is dropped.

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    $self->{verbose} = 0 unless $params->{verbose};
    bless $self, $class;
    return $self;
}

=head extract

Gets the parsed ARRAYRef of rows from StreamParser and Extractor, and validates the data elements.

=cut

sub validate {
    my ($self, $filename, $rows) = @_;

    my $ccnt = TranslationTables::SourceValidationRules::getRuleColumns($filename);
    return undef unless $ccnt;

    my @validated;
    for (my $i=0 ; $i<@$rows ; $i++) {
      my $cols = $rows->[$i];

      my $invalid;
      for (my $j=0 ; $j<@$cols ; $j++) {
        if (scalar(@$cols) != $ccnt) {
            warn "PreProcessor::Validator::validate($filename):> Parsed column count mismatches expected column count. Parsed '".scalar(@$cols)."', expected '$ccnt' columns. Skipping row:\n    ".recurseJoin(',',@$cols)."\n";
            last();
        }

        my $rules = TranslationTables::SourceValidationRules::getRules($filename, $j);
        $rules = [$rules] unless ref($rules) eq 'ARRAY';

        for (my $k=0 ; $k<scalar(@$rules) ; $k++) {
            unless( $self->_validate_colum($filename, $j, $rules->[$k]->{type}, $cols->[$j]->[$k]) ) {
                $invalid = 1;
                last();
            }
        }
        last() if $invalid;
      }
      push @validated, $rows->[$i] unless $invalid;
    }

    return \@validated;
}

=head _validate_colum

=cut

sub _validate_colum {
    my ($self, $filename, $col_index, $type, $columnData) = @_;

    my $valid;
#    my $optional = $1 if $type =~ s/^(\?)//;
    my $optional = 1;
    if ($type =~ m/^int/) {
        if ($columnData =~ m/^\d+$/) {
            return 1;
        }
    }
    elsif ($type =~ m/^string/) {
        if ($columnData =~ m/^.*$/) {
            return 1;
        }
    }
    elsif ($type =~ m/^double/) {
        if ($columnData =~ m/^\d+[.,]?\d*$/) {
            return 1;
        }
    }
    elsif ($type =~ m/^boolean/) {
        if ($columnData =~ m/^(True|False)$/) {
            return 1;
        }
    }
    elsif ($type =~ m/^datetime/) {
        if ($columnData =~ m/^(\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)/) {
            return 1;
        }
    }
    elsif ($type =~ m/^key/) {
        if ($columnData =~ m/^([0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12})$/) {
            return 1;
        }
    }
    else {
        warn "PreProcessor::Validator::_validate_colum():> Unknown type '$type'.\n";
        return undef;
    }

    if ($optional && ($columnData eq '' || not($columnData))) {
        return 1;
    }

    warn "PreProcessor::Validator::_validate_colum():> Validating column data '$columnData' as type '$type' failed, for file '$filename' column '$col_index'.\n";
    return undef;
}

sub recurseJoin {
    my ($sep, $array) = @_;

    my @sb;
    foreach my $a (@$array) {
        if (ref($a) eq 'ARRAY') {
            foreach my $b (@$a) {
                push @sb, $b;
            }
        }
        else {
            push @sb, $a;
        }
    }
    return join($sep, @sb);
}

1;
