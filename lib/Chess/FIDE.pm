package Chess::FIDE;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Exporter;
use Carp;
use LWP::UserAgent;
use IO::File;
use IO::String;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Archive::Zip::MemberRead;

use Chess::FIDE::Player qw(@FIDE_field);

our @ISA = qw(Exporter);

our $VERSION = '1.11';

my $data_offsets = [
	[qw(title 45)],
	[qw(federation 49)],
	[qw(rating   54)],
	[qw(games   59)],
	[qw(year  65)],
	[qw(flags  70)],
];

our $DATA_URL = 'http://ratings.fide.com/download/players_list.zip';

sub new ($;@) {

    my $self  = shift;
    my $class = ref($self) || $self;
    my %param = @_;

    my $fide = [];
    my $line;

    bless $fide,$class;
    if ($param{-file}) {
		my $fh = IO::File->new($param{-file},'r');
		if (defined $fh) {
			$fide->parseFile($fh);
		}
		else {
			warn "$!: $param{-file}\n";
			return {};
		}
    }
    elsif ($param{-www}) {
        my $ua = LWP::UserAgent->new();
        $ua->proxy(['http'],$param{-proxy}) if $param{-proxy};
		my $response = $ua->get($DATA_URL);
		my $webcontent;
		if ($response->is_success) {
			$webcontent = $response->content();
		}
		else {
			warn "Cannot download playerfile: Check your network connection\n";
			return 0;
		}
        my $fh = IO::String->new(\$webcontent) or die "BLAAAH\n";
        my $zip = Archive::Zip->new();
        my $status = $zip->readFromFileHandle($fh);
		unless ($status == AZ_OK) {
			warn "Problems unzipping the downloaded file";
			return 0;
		}
        my $membername;
        for $membername ($zip->memberNames()) {
            my $fh2 = Archive::Zip::MemberRead->new($zip, $membername);
			return 0 unless defined $fh2;
			$fide->parseFile($fh2);
        }
		$fh->close();
    }
	else {
		warn "No source (-file or -www) given";
	}
    return $fide;
}

sub parseFile ($$) {

	my $fide = shift;
	my $fh   = shift;

	my $line;
	while (defined($line = $fh->getline())) {
		next unless $line =~ /^\s*\d/;
		my $player = $fide->parseLine($line);
		push(@{$fide}, $player) if $player;
	}
	$fh->close();
}

sub parseIdAndName ($$) {

	my $self = shift;
	my $id_and_name = shift;

	my ($id, $givenname, $surname) =
		($id_and_name =~ /^\s*(\d+)\s+(.*?)\,?\s+(\S+|\S+\s+\S+)/);

    if ($id_and_name =~ /\S\,\s*\S/) {
		my $tmp = $surname;
		$surname = $givenname;
		$givenname = $tmp;
    }
    $givenname =~ s/^\s+//;
    $givenname =~ s/\s+$//;
    $surname =~ s/^\s+//;
    $surname =~ s/\s+$//;
	my $name =
		!$givenname ? $surname : !$surname ? $givenname : "$givenname $surname";

	return ($id, $name, $givenname, $surname);
}

sub parseRest ($$){

	my $self = shift;
	my $rest = shift;

	my %data = ();

	my $start_offset = $data_offsets->[0][1];
	for my $i (0..$#{$data_offsets}) {
		my $offset = $data_offsets->[$i][1] - $start_offset;
		my $d_offset = $i == $#{$data_offsets} ?
			"" : $data_offsets->[$i+1][1] - $data_offsets->[$i][1];
		last if $offset > length($rest);
		if ($i == $#{$data_offsets}) {
			$data{$data_offsets->[$i][0]} = substr($rest, $offset);
		}
		else {
			$data{$data_offsets->[$i][0]} =	substr(
				$rest, $offset,
				$data_offsets->[$i+1][1] - $data_offsets->[$i][1]
			);
		}
		$data{$data_offsets->[$i][0]} =~ s/\s//g;
	}
	return %data;
}

sub parseLine ($$) {

    my $self = shift;
    my $line = shift;

	chomp $line;
	$line =~ s/\s+$//;
	my $id_and_name = substr($line, 0, $data_offsets->[0][1] - 1);
	my $rest = substr($line, $data_offsets->[0][1] - 1);
	my ($id, $name, $givenname, $surname) = $self->parseIdAndName($id_and_name);
	my $player = Chess::FIDE::Player->new(
		id => $id,
		name => $name,
		givenname => $givenname,
		surname => $surname,
	);
	my %rest = $self->parseRest($rest);
	for my $field (keys %rest) {
		$player->$field($rest{$field});
	}

    return $player;
}

sub fideSearch {

    my $fide = shift;
    my $criteria = shift;

	my $found = 0;
    for my $field (@FIDE_field) {
		if ($criteria =~ /^$field /) {
			$criteria =~ s/^($field)/'$_->{'.$field.'}'/ge;
			$found = 1;
			last;
		}
    }
	die "Invalid criteria supplied" unless $found;
    my @player = grep(eval $criteria, @{$fide});
    return @player;
}

1;
__END__

=head1 NAME

Chess::FIDE - Perl extension for FIDE Rating List

=head1 SYNOPSIS

  use Chess::FIDE;
  my $fide = Chess::FIDE->new(-file=>'filename');
  $fide->fideSearch("surname eq 'Kasparov'");

=head1 DESCRIPTION

Chess::FIDE - Perl extension for FIDE Rating List. FIDE is the
International Chess Federation that every quarter of the year
releases a list of its rated members. The list contains about
fifty thousand entries. This module is designed to parse its
contents and to search across it using perl expressions.
A sample from an up-to-date FIDE list is provided in t/data/test-list.txt
The following methods are available:

=over

=item C<Constructor>

$fide = new Chess::FIDE(-file=>'localfile');
$fide = new Chess::FIDE(-www=>1,[-proxy=>proxyaddress]);

There are two types of constructors - one takes a local file
and another one retrieves the up-to-date zip file from the FIDE
site, unzips it on the fly and parses the output immediately.
In case of the second constructor no files are created. Also
usage of an optional proxy is possible in the second case.

Each player entry in the file is scanned against a regexp and
then there is a post-parsing as well which is implemented in
function parseLine. The entry is then stored in an object defined
by the module Chess::FIDE::Player (see its documentation). Every
new object is inserted as a hash member where the FIDE ID of the
player is the key. A sparse array could be used instead, though.

=item C<fideSearch>

@result = $fide->fideSearch("perl conditional");

Example: @result = $fide->fideSearch("surname eq 'Kasparov'");

Searches the fide object for entries satisfying the conditional
specified as the argument. The conditional MUST be a PERL
expression within double quotes. All constant strings should be
expressed within single quotes because the conditional is 'eval'ed
against each entry. Any conditional including a regexp match
that may be eval-ed is valid. For the fields to use in conditionals
see Chess::FIDE::Player documentation.

=back

=head1 CAVEATS

The only unique entry is the id field. There are, for example, two
"Sokolov, Andrei" entries, so a search by name might be ambigious.

Please note that the files are available only for the year 2001 and
later.

=head1 SEE ALSO

Chess::FIDE::Player
http://www.fide.com/
Archive::Zip
LWP::UserAgent

=head1 AUTHOR

Roman M. Parparov, E<lt>roman@parparov.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Roman M. Parparov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

Fide Rating List is Copyright (C) by International Chess Federation
http://www.fide.com

=cut
