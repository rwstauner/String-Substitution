use strict;
use warnings;
use Test::More;
use String::Gsub::Simple qw(gsub);

# [pattern, replacement, {in => out...}, # of warnings for uninitialized]
my @tests = (
	['(e)(.)',     '$1-$2-', {hello => 'he-l-lo'}],
	['.+(e)(.).+', '$1-$2-', {hello => 'e-l-'}],
	['el',         '',       {hello => 'hlo'}],
	['\s+',        '_',      {hello => 'hello', 'he ll o' => 'he_ll_o', '  ' => '_'}],
	[' ',          '_',      {hello => 'hello', 'he ll o' => 'he_ll_o', '  ' => '__'}],
	['^\d{1,3}$', '', {'1',     ''}],
	['^\d{1,3}$', '', {'12',    ''}],
	['^\d{1,3}$', '', {'123',   ''}],
	['^\d{1,3}$', '', {'1234',  '1234'}],
	['^\d{1,3}$', '', {'12345', '12345'}],
	['^\d{0,3}$', '', {'1',     ''}],
	['^\d{0,3}$', '', {'12',    ''}],
	['^\d{0,3}$', '', {'123',   ''}],
	['^\d{0,3}$', '', {'1234',  '1234'}],
	['^\d{0,3}$', '', {'12345', '12345'}],
	[qr'(^(; )+|(; ?)+$)', '', {'; Hi; ; There; ; ', 'Hi; ; There', 'Hi; ; ; There; ; ' => 'Hi; ; ; There', '; ; Hi; ; There' => 'Hi; ; There'}],
	[qr'(; ){2,}', '; ', {'Hi; There', => 'Hi; There', 'Hi; ; There' => 'Hi; There', 'Hi; ; ; There' => 'Hi; There'}],
	# the (.)? doesn't match in 'Rd' and is referenced twice in the replacement, hence 2 warnings
	[qr'^[Rr](.)?d$', 'gr$1$1n', {'Rd' => 'grn', 'red' => 'green', rod => 'groon'}, 2],
	[qr'^[Rr](.?)d$', 'gr$1$1n', {'Rd' => 'grn', 'red' => 'green', rud => 'gruun'}],
	[qr'(o)(.)',      '$1$2$3',  {'giblet' => 'giblet', 'goober' => 'goober'}, 1],
	[qr'([a-z])oo', '${1}00', {'goober', 'g00ber', 'floo goo noo' => 'fl00 g00 n00'}],
	[qr'0', '', {'0' => '', '1' => '1'} ],
	[qr'(hello)', '$1 there, you', {'hell' => 'hell', 'hello' => 'hello there, you', 'hellos' => 'hello there, yous'}],
	[qr'^0$', '0-0-0 0:0:0', {0 => '0-0-0 0:0:0', 20101228 => 20101228} ],
	[qr'(\d{4})(\d{2})(\d{2})', '$1/$2/$3 00:00:00', {20101228 => '2010/12/28 00:00:00', 201012 => 201012} ],
);

sub sum { my $s = 0; $s += $_ for @_; $s }
plan tests => sum(map { scalar(values %{$_->[2]}) + 1 + ($_->[3]||0) } @tests); # tests + warnings

foreach my $test ( @tests ){
	my ($pattern, $replacement, $hash, $warning) = (@$test, 0);
	my $warned = 0;
	while( my ($string, $expected) = each %$hash ){
		my $s = $string;

		local $SIG{__WARN__} = sub {
			++$warned;
			like($_[0], qr/uninitialized/, "warning uninitialized ($s)");
		};

		is(gsub($s, $pattern, $replacement), $expected, "gsub: '$s' =~ s{$pattern}{$replacement}");
	}
	ok($warned == $warning, 'expected number of warnings');
}
