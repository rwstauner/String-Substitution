package String::Gsub::Simple;
# ABSTRACT: Simple runtime [g]sub functions

=head1 SYNOPSIS

	use String::Gsub::Simple -copy;

	my $subbed = gsub($string, $pattern, $replacement);

=cut

# TODO: document copy/modify/context options
# TODO: document/test replacement as sub rather than string

use strict;
use warnings;
use Sub::Exporter 0.982;
{
	my $exports = {
		exports => [qw(interpolate_match_vars last_match_vars)],
		groups => {}
	};
	my @funcs = qw(sub gsub);
	foreach my $suffix ( qw(copy modify context) ){
		push(@{ $exports->{exports} }, map { "${_}_${suffix}" } @funcs);
		$exports->{groups}->{$suffix} = [
			map { ("${_}_${suffix}" => { -as => $_ }) } @funcs
		];
	}
	Sub::Exporter::setup_exporter($exports);
}

=func gsub_copy

	$subbed = gsub_copy($string, $pattern, $replacement);
	# $string unchanged

Perform global substitution on a copy of the string and return the copy.

=cut

sub gsub_copy {
	my ($string, $pattern, $replacement) = @_;
	$string =~ s/$pattern/
		_replacement_sub($replacement)->(last_match_vars());/ge;
	return $string;
}

=func gsub_modify

	gsub_modify($string, $pattern, $replacement);
	# $string has been modified

Perform global substitution and modify the string.
Returns the result of the C<s///> operator
(number of substitutions performed if matched, empty string if not).

=cut

sub gsub_modify {
	my ($string, $pattern, $replacement) = @_;
	return $_[0] =~ s/$pattern/
		_replacement_sub($replacement)->(last_match_vars());/ge;
}

=func gsub_context

	gsub_context($string, $pattern, $replacement);
	# $string has been modified
	
	$subbed = gsub_context($string, $pattern, $replacement);
	# $string unchanged

If called in a void context this function calls L</gsub_modify>.
Otherwise calls L</gsub_copy>.

=cut

sub gsub_context {
	return defined wantarray
		? gsub_copy(@_)
		: gsub_modify(@_);
}

=func interpolate_match_vars

	$interpolated = interpolate($string, \@match_vars);

Replaces any digit variables in the string
with the corresponding elements from the match_vars arrayref
(returned from L</last_match_vars>).

Substitutes single and multiple digits such as C<$1> and C<${12}>.

A literal C<'$1'> can be escaped/backslashed in the normal way.
Any escaped (backslashed) characters will remain in the string
and the backslash will be removed (also counts for doubled backslashes):

	$string = 'the';
	$pattern = 't(h)e';
	
	# replacement => output
	
	# '-$1-'        => '-h-'
	# '-\\$1-'      => '-$1-'
	# '-\\\\$1-'    => '-\\h-'
	# '-\\\\\\$1-'  => '-\\$1-'
	# '-\\x\\$1-'   => '-x$1-'
	# '-\\x\\\\$1-' => '-x\\h-'

=cut

sub interpolate_match_vars {
	my ($replacement, $matched) = @_;
	my $string = $replacement;
	$string =~
		s/
			(?:
				\\(.)                  # grab escaped characters (including $)
			|
				(?:
					\$\{([1-9]\d*)\}   # match "${1}"
				|
					\$  ([1-9]\d*)     # match "$1"
				)
			)
		/
			defined $1
				? $1                   # if something was escaped drop the \\
				: $matched->[$2 || $3] # else use braced or unbraced number
		/xge;
	return $string;
}

=func last_match_vars

	$match_vars = last_match_vars();

Store the numeric match vars (C<$1>, C<$2>, ...) from the last C<m//>
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

=func sub_copy

	$subbed = sub_copy($string, $pattern, $replacement);
	# $string unchanged

Perform a single substitution on a copy of the string and return the copy.

=cut

sub sub_copy {
	my ($string, $pattern, $replacement) = @_;
	$string =~ s/$pattern/
		_replacement_sub($replacement)->(last_match_vars());/e;
	return $string;
}

=func sub_modify

	sub_modify($string, $pattern, $replacement);
	# $string has been modified

Perform a single substitution and modify the string.
Returns the result of the C<s///> operator
(number of substitutions performed if matched, empty string if not).

=cut

sub sub_modify {
	my ($string, $pattern, $replacement) = @_;
	return $_[0] =~ s/$pattern/
		_replacement_sub($replacement)->(last_match_vars());/e;
}

=func sub_context

	sub_context($string, $pattern, $replacement);
	# $string has been modified
	
	$subbed = sub_context($string, $pattern, $replacement);
	# $string unchanged

If called in a void context this function calls L</sub_modify>.
Otherwise calls L</sub_copy>.

=cut

sub sub_context {
	return defined wantarray
		? sub_copy(@_)
		: sub_modify(@_);
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

Plus I thought the implementation could be simpler.
Hence the name.  I hope this is simple (at least to use).

=end :list

=cut
