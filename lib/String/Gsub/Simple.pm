package String::Gsub::Simple;
# ABSTRACT: Simple runtime [g]sub functions

=head1 SYNOPSIS

	use String::Gsub::Simple qw(gsub);
	gsub($string, $pattern, $replacement);

=cut

use strict;
use warnings;
use Sub::Exporter 0.982;
{
	my $exports = {
		exports => [ qw(gsub) ],
	};
	Sub::Exporter::setup_exporter($exports);
}

=func gsub

	gsub($str, qr/pattern/, 'replacement $1');

=cut

sub gsub {
	my ($data, $pattern, $replacement) = @_;
	$data =~
		s/$pattern/
			# store the match vars from the \$pattern
			my $matched = do {
				no strict 'refs';
				['', map { ($$_) || '' } ( 1 .. $#- )];
			};
			# substitute them into \$replacement
			(my $rep = $replacement) =~
				s!\$(?:\{(\d+)\}|(\d))!$matched->[($1 or $2)]!ge;
			$rep;/xge;
	return $data;
}

1;

=for stopwords gsub runtime

=head1 DESCRIPTION

This module is a collection of functions to enable
(global) substitution on a string using a replacement string or function
created at runtime.

It was designed to take in the string, pattern, and replacement string
from input at runtime and process the substitution without doing an C<eval>.

The replacement string may contain [numbered] match vars (C<$1> or C<${1}>)
which will be interpolated (by using another C<s///> rather than C<eval>).

Other names for this module could have been:

=for :list
* C<String::Gsub::Simplistic>
* C<String::Gsub::NoEval>
* C<String::Gsub::Dumb>

=head1 BUGS AND LIMITATIONS

Probably a lot.

The replacement string only I<interpolates> (term used loosely)
numbered match vars (like C<$1> or C<${12}>).

=cut

=head1 SEE ALSO

=begin :list

* L<String::Gsub>

I tried to use this, but when I couldn't get it to install
I decided to polish up an old function I had written a while back
and try to make it reusable.

=end :list

=cut
