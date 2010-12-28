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
	$data =~ s/$pattern/_replacement_sub($replacement)->(last_match_vars());/ge;
	return $data;
}

=func interpolate_match_vars

	$interpolated = interpolate($string, \@match_vars);

Replaces any digit variables in the string
with the corresponding elements from the match_vars array
(returned from L</last_match_vars>).

Substitutes single and multiple digits such as C<$1> and C<${12}>.

=cut

sub interpolate_match_vars {
	my ($replacement, $matched) = @_;
	my $str = $replacement;
	$str =~ s/\$\{(\d+)\}/$matched->[$1]/g;
	$str =~   s/\$(\d+)/$matched->[$1]/g;
	return $str;
}

=func last_match_vars

	$match_vars = last_match_vars();

Store the numeric match vars (C<$1>) from the last C<m//>
in an arrayref.

The first element of the array is undef
to make it simple and clear that the digits
correspond to their index in the array:

	$m = [undef, $1, $2]
	$m->[1] ; # == $1
	$m->[2] ; # == $2

This can be useful when you want to save the captured groups from
a previous C<m//> while doing another C<m//>.

This function is used by the substitution functions.

=cut

sub last_match_vars {
	no strict 'refs';
	[undef, map { ($$_) || '' } ( 1 .. $#- )];
}

# Return a sub that will get matched vars array passed to it

sub _replacement_sub {
	my ($rep) = @_;
	# if $rep is not a sub, assume it's a string to be interpolated
	ref $rep
		? $rep
		: sub { interpolate_match_vars($rep, @_); };
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
