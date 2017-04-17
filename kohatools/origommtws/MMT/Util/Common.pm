package MMT::Util::Common;

use Modern::Perl;


sub executeShell {
    my ($cmd, $realtimePrinting) = @_;

    open(my $FH, $cmd);
    my @sb;
    while (<$FH>) {
        push @sb, $_."\n";
        print $_ if $realtimePrinting;
    }
    close($FH);
    return \@sb;
}

sub printTime {
    my ($startTime) = @_;
    my $elapsed = time() - $startTime; #All in seconds.

    return sprintf("%02d:%02d:%02d",(gmtime($elapsed))[2,1,0]);
}

=head3 Replace the character in the given position with the substitute string.
=item @Param1 the string scalar.
=item @param2 the location scalar starting from 0 which to substitute
=item @param3 the substitute string used to make the substitution
=cut
sub characterReplace($$$) {
	my $str = $_[0];
	$str =~ s/(?<=^.{$_[1]})./$_[2]/;
	return $str;
}

1;
