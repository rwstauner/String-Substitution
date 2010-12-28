use strict;
use warnings;
use Test::More;
use String::Gsub::Simple qw(gsub);

my @tests = (
	[qw'hello (e)(.) $1-$2- he-l-lo'],
	[qw'hello .+(e)(.).+ $1-$2- e-l-'],
	[qw'hello el', '', 'hlo'],
	[qw'1    ^\d{1,3}$', '', ''],
	[qw'12   ^\d{1,3}$', '', ''],
	[qw'123  ^\d{1,3}$', '', ''],
	[qw'1234 ^\d{1,3}$', '', '1234'],
);

plan tests => scalar @tests;

foreach my $test ( @tests ){
	my ($string, $pattern, $replacement, $expected) = @$test;
	my $s;

	is(gsub(($s = $string), $pattern, $replacement), $expected, "gsub: @{[map { qq['$_'] } @$test]}");
}
