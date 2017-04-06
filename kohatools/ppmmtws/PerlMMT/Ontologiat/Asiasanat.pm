package Ontologiat::Asiasanat;

use strict;
use warnings;
#use diagnostics;

use XML::TreePP;
use LWP::Simple; # for downloading the files
use File::Basename;

use utf8;

#Contains the Onki-repositories and their URL's.
my %files = (
	'kauno.rdf' => 'http://onki.fi/fi/browser/downloadfile/kauno?o=http%3A%2F%2Fwww.yso.fi%2Fonto%2Fkauno&f=kauno%2Fkauno-skos.rdf',
	'musa.rdf' => 'http://onki.fi/fi/browser/downloadfile/musa?o=http%3A%2F%2Fwww.yso.fi%2Fonto%2Fmusa&f=musa%2Flib.helsinki-musa.rdf',
	'ysa.rdf' => 'http://onki.fi/fi/browser/downloadfile/ysa?o=http%3A%2F%2Fwww.yso.fi%2Fonto%2Fysa&f=ysa%2Flib.helsinki-ysa-skos.rdf'
);


sub alphaonly {
    my $s = shift;
    $s =~ s/[^a-zA-Z0-9öäåÖÄÅ]//g;
    return $s;
}

sub save_word_def {
    my ($self, $lang, $text, $preflabel) = @_;
	
    return if (!$lang || !$text || $lang eq '' || $text eq '');

    if ($text =~ m/^(.+) (\(.+\))$/) {
		my $ntxt = $1;
		my $dtxt = $2;
		$self->save_word_def($lang, $ntxt, $preflabel) if (!($self->{'lang'}->{$lang}->{$ntxt}));
		if ($dtxt =~ m/^\(= (.+)\)$/) {
			my $eqtxt = $1;
			$self->save_word_def($lang, $eqtxt, $preflabel) if (!($self->{'lang'}->{$lang}->{$eqtxt}));
		}
		return; ##EGDATA-119
    }

    my $val = (($preflabel && (($preflabel ne $text) || ($lang ne $self->{'main_lang'}))) ? $preflabel : 1);

    $self->{'lang'}->{$lang}->{$text} = $val;
    $self->{'lang'}->{$lang}->{lc($text)} = $text if (!($self->{'lang'}->{$lang}->{lc($text)}));
    $self->{'lang'}->{$lang}->{alphaonly(lc($text))} = $text if (!($self->{'lang'}->{$lang}->{alphaonly(lc($text))}));
}



# $self->init();
#Initializes this object and returns the object reference
# Param1 : path, the directory where all source files are located. They will be downloaded here and loaded to memory from here. This folder will be created if it is missing.
sub init {
    my $class = shift;
	my $self = {};
	
    $self->{'main_lang'} = 'fi';
    $self->{'lang'} = { };
	$self->{'sourceDirectory'} = shift;
	
    bless($self, $class);
    return $self;
}


# $self->download_file($url, $fname);
sub download_file {
    my ($self, $url, $fname) = @_;
    my $dirname = $self->{'sourceDirectory'};
    mkdir($dirname) if (!(-e $dirname));

    getstore($url, $fname);
    push(@{$self->{'files'}}, $fname);
}


# $self->download_default_files($force_download);
sub download_default_files {
    my ($self, $forcedl) = @_;

    my $dirname = $self->{'sourceDirectory'};

    mkdir($dirname) if (!(-e $dirname));

	#Download the repositories.
	#Iterate the package variable %files, which contains the Onki-repositories and their URL's.
    foreach my $k (keys(%files)) {
		my $fname = $dirname.$k;
		getstore($files{$k}, $fname) if ((! -e $fname) || $forcedl);
    }
}



# $self->processfile("file.rdf")
sub process_file {
    my $self = shift;
    my $dbfile = shift || die "No dbfile for Asiasanat->processfile()";

    my $tpp = XML::TreePP->new();
	$tpp->set( utf8_flag => 1 );
    my $tree = $tpp->parsefile($dbfile);

    my @ntree = @{$tree->{'rdf:RDF'}->{'rdf:Description'}};

    foreach my $nod (@ntree) {
		my %dat = %{$nod};
	
		my $prefLabel;
	
		if (ref($dat{'skos:prefLabel'}) eq 'ARRAY') {
			foreach (@{$dat{'skos:prefLabel'}}) {
				my $lang = $_->{'-xml:lang'};
				my $text = $_->{'#text'};
				if ($lang && $lang eq $self->{'main_lang'}) {
					$prefLabel = sanitatePrefLabel($text);
					last;
				}
			}
			foreach (@{$dat{'skos:prefLabel'}}) {
				my $lang = $_->{'-xml:lang'};
				my $text = $_->{'#text'};
				$text =~ s/^- *synon //;
				$self->save_word_def($lang, $text, $prefLabel);
			}
		} else {
			my $lang = $dat{'skos:prefLabel'}{'-xml:lang'};
			my $text = $dat{'skos:prefLabel'}{'#text'};
			$prefLabel = sanitatePrefLabel($text) if ($lang && $lang eq $self->{'main_lang'});
			$self->save_word_def($lang, $text, $prefLabel);
		}
	
		if (ref($dat{'skos:altLabel'}) eq 'ARRAY') {
			foreach (@{$dat{'skos:altLabel'}}) {
				my $lang = $_->{'-xml:lang'};
				my $text = $_->{'#text'};
				$text =~ s/^- *synon //;
				$self->save_word_def($lang, $text, $prefLabel);
			}
		} else {
			my $lang = $dat{'skos:altLabel'}{'-xml:lang'};
			my $text = $dat{'skos:altLabel'}{'#text'};
			$self->save_word_def($lang, $text, $prefLabel);
		}


    }
	
	## prefLabel can have some crazy (attachements), so getting rid of them, for ex.
	# lapset (sosioekonomiseen ryhmään liittyvä rooli)
	sub sanitatePrefLabel {
		my $prefLabel = shift;
		if ($prefLabel =~ m/^(.+) \(.+\)$/) {
			return $1;
		}
		return $prefLabel;
	}
}

# $self->process_downloaded_files();
sub process_downloaded_files {
	print "Processing Onki onthology\n";
    my $self = shift;
	
	my $dirname = $self->{'sourceDirectory'};
    foreach (keys %files) {
		$self->process_file($dirname.$_);
    }
}

sub normalize_keyword_core {
    my ($self, $keyword, $recur) = @_;

    if (!$keyword) {
		print STDERR "Error: asiasanat->normalize_keyword() with no keyword.";
		return "";
    }

    return ( $keyword, 'ERROR' ) if ($recur && ($recur > 10));

    my $recursion = ($recur ? ($recur + 1) : 1);

    my $w;
    foreach my $l (keys($self->{'lang'})) {

		my $tmp = $self->{'lang'}->{$l};
	
		$w = $tmp->{$keyword};
		return $keyword if ($w && $w eq '1');
		$w = $tmp->{lc($keyword)} if (!$w);
		return lc($keyword) if ($w && $w eq '1');
		$w = $tmp->{alphaonly(lc($keyword))} if (!$w);
		return alphaonly(lc($keyword)) if ($w && $w eq '1');
		return $self->normalize_keyword_core($w, $recursion) if ($w && ($keyword ne $w));
    }
    return ( $keyword, 'NOTFOUND' );
}


# $self->normalize_keyword("keyword");
sub normalize_keyword {
    my ($self, $keyword) = @_;
    my @kw = $self->normalize_keyword_core($keyword, 1);
    return $kw[0];
}

# $self->is_unknown_keyword("keyword");
sub is_unknown_keyword {
    my ($self, $keyword) = @_;
    my @kw = $self->normalize_keyword_core($keyword, 1);

    return 1 if ($kw[1] && ($kw[1] eq 'NOTFOUND'));
    return 0;
}



1;

__END__
