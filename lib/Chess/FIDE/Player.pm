package Chess::FIDE::Player;

use 5.008003;
use strict;
use warnings;

use Exporter;
use Carp;

our @ISA = qw(Exporter);

our @FIDE_field = qw(id surname name title country rating games birthday flag);

our @EXPORT = qw(
		 @FIDE_field
		);

our $VERSION = '1.00';

sub new {

    my $self = shift;
    my $class = ref($self) || $self;
    my %param = @_;
    my $player = {};
    my %init = (id=>3000000,surname=>'Surname',name=>'Name',title=>' ',country=>'FID',
		rating=>1000,games=>0,birthday=>'  .  .  ',flag=>' ');
    bless $player,$class;
    my $id = $init{id};
    for (@FIDE_field) {
	unless (defined $param{$_}) {
	    if ($_ eq 'id') {
		$param{id} = $id++;
		print "ID $param{id}\n";
	    }
	    else {
		$param{id} = $init{id};
	    }
	}
	$player->{$_} = $param{$_};
    }
    return $player;
}
sub value {

    my $player = shift;
    my $field = shift;
    my $value = shift;

    return undef if !grep(/^$field/,@FIDE_field);
    $player->{$field} = $value if defined $value;
    return $player->{$field};
}
sub id {

    my $player = shift;

    return $player->{id};
}
# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

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
