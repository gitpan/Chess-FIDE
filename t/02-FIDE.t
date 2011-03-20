#!perl

use strict;
use warnings;

use Chess::FIDE;
use Test::More tests => 30003;

my $fide = Chess::FIDE->new();
isa_ok($fide, 'Chess::FIDE');
is_deeply($fide, [], "empty object");
$fide = Chess::FIDE->new(
	-file => 't/data/test-list.txt',
);
is(scalar @{$fide}, 9999, "All players parsed");
for my $player (@{$fide}) {
	ok($player->id, "Id parsed " . $player->id);
	ok($player->name, "Some name obtained " . $player->name);
	ok($player->federation, "Some federation obtained " . $player->federation);
}
my @res = $fide->fideSearch("id == 4158814");
is(scalar @res, 1, "Exact match found");
@res = $fide->fideSearch("surname eq 'Andreoli'");
is(scalar @res, 4, "Four exact matches found");
$fide = Chess::FIDE->new(
	-www => 1,
);
ok(scalar @{$fide} > 99999, "Lots of players parsed");

