use strict;
use warnings;

package String::Substitution;
# ABSTRACT: Simple runtime string substitution functions

=head1 SYNOPSIS

	use String::Substitution -copy;

	my $subbed = gsub($string, $pattern, $replacement);

=cut

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

	$interpolated = interpolate_match_vars($string, @match_vars);

Replaces any digit variables in the string
with the corresponding elements from the match_vars array
(returned from L</last_match_vars>).

Substitutes single and multiple digits such as C<$1> and C<${12}>.

A literal C<$1> can be escaped in the normal way.
Any escaped (backslashed) characters will remain in the string
and the backslash will be removed (also counts for doubled backslashes):

	$string = 'the';
	$pattern = 't(h)e';

	# 'replacement' => 'output'  # appearance when printed

	# '-$1-'        => '-h-'     # prints: -h-
	# '-\\$1-'      => '-$1-'    # prints: -$1-
	# '-\\\\$1-'    => '-\\h-'   # prints: -\h-
	# '-\\\\\\$1-'  => '-\\$1-'  # prints: -\$1-
	# '-\\x\\$1-'   => '-x$1-'   # prints: -x$1-
	# '-\\x\\\\$1-' => '-x\\h-'  # prints: -x\h-

This function is used when the substitution functions receive
a string as the I<replacement> parameter.
Essentially:

	$interpolated = interpolate_match_vars($replacement, last_match_vars());

=cut

sub interpolate_match_vars {
	my ($replacement, @matched) = @_;
	my $string = $replacement;
	# Handling backslash-escapes and variable interpolations
	# in the same substitution (alternation) keeps track of the position
	# in the string so that we don't have to count backslashes.
	$string =~
		s/
			(?:
				\\(.)                  # grab escaped characters (including $)
			|
				(?:
					\$\{([1-9]\d*)\}   # match "${1}" (not unrelated '${0}')
				|
					\$  ([1-9]\d*)     # match  "$1"  (not unrelated '$0')
				)
			)
		/
			defined $1
				? $1                   # if something was escaped drop the \\
				: $matched[$2 || $3];  # else use braced or unbraced number
				                       # ($2 will never contain '0')
		/xge;
	return $string;
}

=func last_match_vars

	@match_vars = last_match_vars();

Return a list of the numeric match vars
(C<$1>, C<$2>, ...) from the last successful pattern match.

The first element of the array is C<undef>
to make it simple and clear that the digits
correspond to their index in the array:

	@m = (undef, $1, $2);
	$m[1]; # same as $1
	$m[2]; # same as $2

This can be useful when you want to save the captured groups from
a previous pattern match so that you can do another
(without losing the previous values).

This function is used by the substitution functions.
Specifically, it's result is passed to the I<replacement> coderef
(which will be L</interpolate_match_vars> if I<replacement> is a string).

In the future the first element
may contain something more useful than C<undef>.

=cut

sub last_match_vars {
	no strict 'refs';
	return (
		# fake $& with a substr to avoid performance penalty (see perlvar)
		#(@_ ? substr($_[0], $-[0], $+[0] - $-[0]) : undef),
		undef,
		# $1, $2 ..
		map { ($$_) || '' } ( 1 .. $#- )
	);
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

=for stopwords gsub runtime precompiled

=head1 DESCRIPTION

This module is a collection of functions to enable
(global) substitution on a string using a replacement string or function
created at runtime.

It was designed to take in the string, pattern, and replacement string
from input at runtime and process the substitution without doing an C<eval>.

The replacement string may contain [numbered] match vars (C<$1> or C<${1}>)
which will be interpolated (by using another C<s///> rather than C<eval>).

=head1 USAGE

The C<sub_*> and C<gsub_*> functions come in three variants:

=begin :list

* C<copy> - Performs the substitution on a copy and returns the copy.

* C<modify> - Modifies the variable in-place (just like C<< $s =~ s/// >>).

=item *

C<context> - Guess by the context which version to use.
In void context execution will pass to the C<modify> variant,
otherwise pass to the C<copy> variant.
It's probably best to use C<copy> or C<modify> explicitly
but the choice is yours.

=end :list

Each version of each function takes three (scalar) arguments:

=for :list
1. string on which to perform the substitution
2. search pattern (string or precompiled C<qr//> pattern)
3. replacement (string or coderef)

Besides a string, the replacement can also be a coderef
which will be called for each substitution.
The regular pattern match variables will be available
inside the coderef (C<$1>) as you would expect.

	# uppercase the first captured group in $pattern:
	gsub($string, $pattern, sub { uc $1 });

For convenience, however, the coderef will be passed the list
returned from L</last_match_vars>
to allow you to do other pattern matching without losing those variables.

	# can also use @_ (same as above)
	gsub($string, $pattern, sub { uc $_[1] });

	# which is essentially:
	# $string =~ s/$pattern/ $codref->( last_match_vars() );/e

	# which allows you to get complicated (an example from t/functions.t):
	gsub(($string = 'mod'), '([a-z]+)',
		sub { (my $t = $1) =~ s/(.)/ord($1)/ge; "$_[1] ($1) => $t" });
	# produces 'mod (d) => 109111100'
	# notice that $1 now produces 'd' while $_[1] still has 'mod'

See L</FUNCTIONS> for more information
about each individual substitution function.

=head1 EXPORTS

This module exports nothing by default.
All functions documented in this POD are available for export upon request.

This module uses L<Sub::Exporter> which allows extra functionality:

There are predefined export groups
corresponding to each of the variants listed above.
Importing one (and only one) of these groups will
rename the functions (dropping the suffix) so that
the functions in your namespace will be named C<sub> and C<gsub>
but will reference the variation you specified.

Surely it is more clear with examples:

	package Local::WithCopy;
	use String::Substitution -copy;
	# now \&Local::WithCopy::gsub == \&String::Substitution::gsub_copy

	package Local::WithModify;
	use String::Substitution -modify;
	# now \&Local::WithModify::gsub == \&String::Substitution::gsub_modify

	package Local::WithContext;
	use String::Substitution -context;
	# now \&Local::WithContext::gsub == \&String::Substitution::gsub_context

B<Note> that C<String::Substitution> does not actually have functions
named C<sub> and C<gsub>, so you cannot do this:

	$subbed = String::Substitution::gsub($string, $pattern, $replacement);

But you are free to use the full names (with suffixes):

	$subbed = String::Substitution::gsub_copy($string, $pattern, $replacement);
	String::Substitution::gsub_modify($string, $pattern, $replacement);
	String::Substitution::gsub_context($string, $pattern, $replacement);

That is the magic of L<Sub::Exporter>.

If you are not satisfied with this
see L<Sub::Exporter> for other ways to get what you're looking for.

=head1 BUGS AND LIMITATIONS

Probably a lot.

The replacement string only I<interpolates> (term used loosely)
numbered match vars (like C<$1> or C<${12}>).
See L</interpolate_match_vars> for more information.

This module does B<not> save or interpolate C<$&>
to avoid the "considerable performance penalty" (see L<perlvar>).

=cut

=head1 SEE ALSO

=begin :list

* L<String::Gsub>

I tried to use this, but when I couldn't get it to install
I decided to polish up an old function I had written a while back
and try to make it reusable.

Plus I thought the implementation could be simpler.

=end :list

=cut
