package MMT::PreProcessor::StreamParser;

use Modern::Perl;

use Encode;
use File::Slurp;
use File::Basename;
use YAML::XS;
use Text::CSV_XS;

use TranslationTables::SourceValidationRules;

=head StreamParser

=head SYNOPSIS

StreamParser is a crude parser which slurps the contents of a file, then processes
it character by character. Parser can change modes from normal .csv/.tsv parser to a
xml-parser, based on the source validation rules.
This parser only read data and cuts it into rows and columns using the column-specific parser.

You can configure the
  line_separator (default \n),
  quote character (default "),
  column separator (default \t)
from the master config.yaml.

=cut

sub new {
    my ($class, $params) = @_;
    my $self = {};
    $self->{_config} = $params;
    $self->{verbose} = $params->{verbose} || 0;
    bless $self, $class;
    return $self;
}

sub config {
    my ($self) = @_;
    return $self->{_config};
}

sub parse_file {
    my ($self, $filename) = @_;

    my $ccnt = TranslationTables::SourceValidationRules::getRuleColumns($filename);
    return undef unless $ccnt;
    $self->{col_rule} = TranslationTables::SourceValidationRules::getParser($filename, 0);

    my $sep = $self->config->{separator};
    my $trm = $self->config->{line_terminator};
    my $quo = $self->config->{quote};
    my $sta = 'inCol';
    $self->{c_ary} = undef;
    $self->{c_ary_idx} = undef;
    $self->{col_i} = 0;
    $self->{cols} = []; #Collect the extracted columns
    $self->{rows} = []; #Collect the extracted rows
    $self->{columns} = [];
    $self->{colBuilder} = [];

    open(my $SFH, "<:encoding(latin1)", $self->config->{origoSourceBaseDir}.$filename) or die $!;
    <$SFH>; <$SFH>; #Skip header lines
    $self->{SFH} = $SFH;

    while (defined(my $c = $self->_nextChar())) {

#DEBUG BREAKPOINT
#      if ($filename eq 'AuktLainaAika.txt' && scalar(@{$self->{rows}}) == 0) {
#        print 1;
#      }

        if($c =~ /($sep)/ && $sta ne 'inQuo') {
          $self->changeColumn($filename, $ccnt);
          next();
        }
        elsif($c =~ /($trm)/ && $sta ne 'inQuo') {
          $self->changeRow($filename, $ccnt);
          next();
        }
    
        if($self->{col_rule} eq 'xml'){
          my $startTag = '';
          while($c ne '<'){$c = $self->_pushChar();}
          $c = $self->_pushChar(); #Skip a beat
          while($c ne '>'){
            $startTag .= $c;
            $c = $self->_pushChar();
          }
          while(1){
            my $endTag = '';
            while($c.$self->_peekChar() ne "</"){
              $c = $self->_pushChar();
            }
            $c = $self->_pushChar(); #Skip a beat
            $c = $self->_pushChar(); #Skip a beat
            while($c ne '>'){
              $endTag .= $c;
              $c = $self->_pushChar();
            }
            if($startTag eq $endTag){
              $self->{col_rule} = 'int'; #We got the xml, now resume normally
              last();
            }
          }
          next();
        }
        elsif($self->{col_rule} ne 'xml') {
          if($c eq $quo) {
            push(@{$self->{colBuilder}}, $c);
            if($sta eq 'inQuo') {
              $sta = 'inCol';
            }
            else {
              $sta = 'inQuo';
            }
            next();
          }
          elsif($sta =~ /(inCol|inQuo)/ && defined($c)) {
            push(@{$self->{colBuilder}}, $c);
          }
        }
    }
    return $self->{rows};
}

sub changeColumn {
    my ($self, $filename, $ccnt) = @_;

    push @{$self->{cols}}, join('', @{$self->{colBuilder}});

    print "PreProcess::StreamParser::changeRow():> INFO, New col '".scalar(@{$self->{cols}})."'\n" if $self->{verbose} > 2;
    print "Previous col: '".join('',@{$self->{colBuilder}})."'\n" if $self->{verbose} > 3;

    $self->{col_i}++;
    $self->{colBuilder} = [];
    $self->{col_rule} = TranslationTables::SourceValidationRules::getParser($filename, $self->{col_i});
}

sub changeRow {
    my ($self, $filename, $ccnt) = @_;

    if ($self->{col_i}+1 != $ccnt) {
        warn "File '$filename', row '".scalar(@{$self->{rows}})."'. Got '".$self->{col_i}."' columns, expected '$ccnt'";
    }
    $self->{col_i} = -1; #Reset to first column, changeColumn increments this to 0
    $self->changeColumn($filename, $ccnt);
    push(@{$self->{rows}}, $self->{cols});

    print "PreProcess::StreamParser::changeRow():> INFO, New row '".scalar(@{$self->{rows}})."'\n" if $self->{verbose} > 1;
    print "Previous row: '".join('',@{$self->{cols}})."'\n" if $self->{verbose} > 2;

    $self->{cols} = [];
}

sub _nextRow {
    my ($self) = @_;
    my $SFH = $self->{SFH};
    my $rawRow = <$SFH>;
    return undef unless $rawRow;
    $rawRow =~ s/\r//g; #Remove windows carriage return
    my @c = split('',$rawRow);
    $self->{c_ary} = \@c;
    $self->{c_ary_idx} = undef;
    return 1 if $rawRow;
}

sub _nextChar {
    my ($self) = @_;

    $self->{c_ary_idx} = -1 if(not(defined($self->{c_ary_idx})));
    $self->{c_ary_idx}++;
    my $char = $self->{c_ary}->[$self->{c_ary_idx}];
    if(not(defined(($char)))) {
        if ($self->_nextRow()) {
            return $self->_nextChar();
        }
    }
    return (defined(($char))) ? $char : undef;
}

sub _peekChar {
    my ($self) = @_;

    $self->{c_ary_idx} = -1 if(not(defined($self->{c_ary_idx})));
    my $char = $self->{c_ary}->[$self->{c_ary_idx}+1];
    if(not(defined(($char)))) {
        if ($self->_nextRow()) {
            return $self->_peekChar();
        }
    }
    return (defined(($char))) ? $char : '';
}

sub _pushChar {
    my ($self) = @_;

    $self->{c_ary_idx} = 0 if(not(defined($self->{c_ary_idx})));
    my $char = $self->{c_ary}->[$self->{c_ary_idx}];
    push(@{$self->{colBuilder}}, $char);
    $self->_nextChar();
}

1;
