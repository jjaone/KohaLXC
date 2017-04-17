package MMT::PreProcessor::Extractor;

use Modern::Perl;

use TranslationTables::SourceValidationRules;

=head Extractor

=head SYNOPSIS

Iterates each row and column and tries to extract values from it using the given
source validation rules.
This is used to find the needed data elements from the noise of the data dumps.

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    bless $self, $class;
    $self->{verbose} = 0 unless $params->{verbose};
    $self->{extractionFailureCounter} = 1;
    return $self;
}

=head extract

Gets the parsed ARRAYRef of rows from StreamParser and extracts hard-to-get values from xml and string columns.

=cut

sub extract {
    my ($self, $filename, $rows) = @_;

    my $ccnt = TranslationTables::SourceValidationRules::getRuleColumns($filename);
    return undef unless $ccnt;

    for (my $i=0 ; $i<@$rows ; $i++) {
      my $cols = $rows->[$i];

      for (my $j=0 ; $j<@$cols ; $j++) {
        my $rules = TranslationTables::SourceValidationRules::getRules($filename, $j);
        $rules = [$rules] unless ref($rules) eq 'ARRAY';

        my @extracted;
        foreach my $r (@$rules) {
            if ($r->{postproc}) {
                my $elem = $self->_extract_colum($filename, $r->{postproc}, $cols, $j);
                push @extracted, $elem;
            }
            else {
                my $elem = $cols->[$j];
                push @extracted, $elem;
            }
        }
        $cols->[$j] = \@extracted;
      }
    }

    return $rows;
}

=head _extract_colum

Extract from the given source data column using the configured post processor.

=cut

sub _extract_colum {
    my ($self, $filename, $postProcessingRule, $columns, $col_index) = @_;
    my $columnData = $columns->[$col_index];

    if ($postProcessingRule =~ m!^grep (.+?)$!) {
        my $regexp = $1;

        if ($columnData =~ m/$regexp/) {
            print '';
            return $1;
        }
        else {
            warn "PreProcessor::Extractor::_extract_colum():> Unable to parse column data '$columnData' with regexp '$regexp', from file '$filename' and column '$col_index'. Tagging with 'FAIL".sprintf("%04d", $self->{extractionFailureCounter})."'\n";
            return "FAIL".sprintf("%04d", $self->{extractionFailureCounter}++);
        }
    }
    else {
        warn "PreProcessor::Extractor::_extract_colum($columnData):> Unknown post processing rule '$postProcessingRule'\n";
    }

    return $columnData;
}

1;
