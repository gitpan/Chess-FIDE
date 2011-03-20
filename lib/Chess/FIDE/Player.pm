package Chess::FIDE::Player;

use 5.008;
use strict;
use warnings;

use Exporter;
use Carp;

our @ISA = qw(Exporter);

our @FIDE_field = qw(
	id surname givenname name title federation rating games year flags
);
our @FIDE_default = (
	0, '', '', '', '', '', 0, 0, 0, ''
);
our @EXPORT = qw(@FIDE_field);
our $AUTOLOAD;
our $VERSION = '1.10';

sub new ($;@) {

    my $self = shift;
    my $class = ref($self) || $self;
    my %param = @_;

    my $player = {};
    bless $player,$class;
	my $f = 0;
    for (@FIDE_field) {
		$player->{$_} = $param{$_} || $FIDE_default[$f];
		$f++;
	}
    return $player;
}

sub AUTOLOAD ($;$) {

	my $self  = shift;
	my $param = shift;

	my $method = $AUTOLOAD;
	$method = lc $method;
	my @path = split(/\:\:/, $method);
	$method = pop @path;
	return if $method =~ /^destroy$/;
	unless (exists $self->{$method}) {
		carp "No such method or property $method";
		return undef;
	}
	$self->{$method} = $param if ($param);
	return $self->{$method};
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Chess::FIDE::Player - Parse player data from FIDE Rating List.

=head1 SYNOPSIS

  use Chess::FIDE::Player qw(@FIDE_field);
  my $player = Chess::FIDE::Player->new(%param);
  print $player->id() . "\n";
  $player->value('field');

=head1 DESCRIPTION

Chess::FIDE::Player - Parse player data from FIDE Rating List.
FIDE is the International Chess Federation that every quarter
of the year releases a list of its rated members. The list
contains about fifty thousand entries. This module provides means
of translation of every entry into a perl object containing all
the fields.

=over

=item C<Constructor>

$player = Chess::FIDE::Player->new(%param);

The constructor creates a hash reference, blesses it and fills it
with parameters passed in %param. The parameters should be fields
corresponding to @FIDE_field (see section 'EXPORT'). If a field is
not defined, a default value contained in %init is used, and if it
is the 'id' field, the next default id is increased by one.

=item C<value>

$player->value('field');
$player->value('field',$value);

First one retrieves a field in the $player object. If the field is not
valid (i.e. not contained in @FIDE_field, an undef is returned. Second
one sets the field to $value, and again in case of an invalid field
undef is returned. Otherwise the new value of the field is returned.

=back

=head2 EXPORT

=over

=item C<@FIDE_field>

 - array of valid fields for the Player object.

=back

=head1 SEE ALSO

Chess::FIDE http://www.fide.com

=head1 AUTHOR

Roman M. Parparov, E<lt>romm@empire.tau.ac.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Roman M. Parparov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

Fide Rating List is Copyright (C) by International Chess Federation
http://www.fide.com

=cut
