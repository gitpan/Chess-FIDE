package Chess::FIDE;

use 5.008003;
use strict;
use warnings;

use Exporter;
use Carp;
use LWP::UserAgent;
use IO::Scalar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Archive::Zip::MemberRead;

use Chess::FIDE::Player qw(@FIDE_field);

our @ISA = qw(Exporter);

our $VERSION = '1.00';

sub new {

    my $self = shift;
    my $class = ref($self) || $self;
    my %param = @_;
    my $fide = {};
    my $line;
    bless $fide,$class;
    if ($param{-file}) {
	my $fh = IO::File->new($param{-file},'r');
	if (defined $fh) {
            while (defined($line = $fh->getline())) {
		next unless $line =~ /^\s*\d/;
		my $player = $self->parseLine($line);
		if ($player eq -1) {
		    $fh->close();
		    return {};
		}
		else {
		    $fide->{$player->id()} = $player;
		}
            }
	    $fh->close();
	}
	else {
	    warn "$!: $param{-file}\n";
	}
    }
    if ($param{-www}) {
	my($mon,$year) = (localtime(time))[4,5];
	my($tmon,$tyear);
	$tyear = sprintf "%02d",$year-100;
	if ($mon < 3) {
	    $tmon = 'jan';
	}
	elsif ($mon < 6) {
	    $tmon = 'apr';
	}
	elsif ($mon < 9) {
	    $tmon = 'jul';
	}
	else {
	    $tmon = 'oct';
	}
        my @content = ();
        my $url = "http://www.fide.com/ratings/download/$tmon${tyear}frl.zip";
        my $ua = LWP::UserAgent->new();
        if ($param{-proxy}) {
            $ua->proxy(['http'],$param{-proxy});
        }
        my $webcontent = $ua->get($url)->content();
        my $fh = IO::Scalar->new(\$webcontent);
        my $zip = Archive::Zip->new();
        my $status = $zip->readFromFileHandle($fh);
	return $fide unless $status == AZ_OK;
        my @membername = $zip->memberNames();
        my $membername;
        my $line;
        for $membername (@membername) {
            my $fh2 =  new Archive::Zip::MemberRead($zip, $membername);
	    return $fide unless defined $fh2;
            while (defined($line = $fh2->getline())) {
		next unless $line =~ /^\s*\d/;
		my $player = $self->parseLine($line);
		if ($player eq -1) {
		    $fh->close();
		    $fh2->close();
		    return {};
		}
		else {
		    $fide->{$player->id()} = $player;
		}
            }
	    $fh2->close();
        }
	$fh->close();
    }
    return $fide;
}
sub parseLine {

    my $self = shift;
    my $line = shift;
    my $player;
    my %param = ();

    $line =~ s/\r\n//;
    my($id,$surname,$name,$title,$country,$rating,$games,$day,$month,$year,$flag) =
      ($line =~ /^\s*(\d+)\s+(.*)\,?(\S+|\S+\s\S+)\s+([a-z]+|\s+)\s+(\S\S\S)\s+(\d+)\s+(\d+)\s+(..)\.(..)\.(..)\s*(\S*)/);
    if ($surname =~ /^(.*)\,(.*)$/) {
	$surname = $1;
	$name = $2.$name;
    }
    if ($name =~ /(.*\S)\s+\s\s\S+/) {
	$name = $1;
    }
    $name =~ s/^\s+//;
    $surname =~ s/^\s+//;
    $name =~ s/\s+$//;
    $surname =~ s/\s+$//;
    $flag = ' ' unless defined $flag;
    $title = substr($line,44,2);
    $title =~ s/\s+$//;
    $title = ' ' unless $title;
    if (defined $id && defined $surname && defined $name && defined $title &&
	defined $country && defined $rating && defined $games && defined $day
	&& defined $month && defined $year && defined $flag) {
	$param{id} = $id; $param{surname} = $surname; $param{name} = $name;
	$param{title} = $title; $param{country} = $country; $param{rating} = $rating;
	$param{games} = $games; $param{flag} = $flag;
	$param{birthday} = $year.$month.$day;
    }
    else {
	warn "Problems with line $line\n";
	return -1;
    }
    $player = Chess::FIDE::Player->new(%param);
    return $player;
}
sub fideSearch {

    my $fide = shift;
    my $criteria = shift;

    for my $field (@FIDE_field) {
	if ($criteria =~ /^$field/) {
	    $criteria =~ s/^($field)/'$fide->{$_}->{'.$field.'}'/ge;
	}
	else {
	    $criteria =~ s/(\W)($field)/$1.'$fide->{$_}->{'.$field.'}'/ge;
	}
    }
    print "Using $criteria\n";
    my @player = grep(eval $criteria, keys %{$fide});
    return map ($fide->{$_},@player);
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
A sample list from April 2004 is provided under filename APR04FRL.TXT
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

Roman M. Parparov, E<lt>romm@empire.tau.ac.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Roman M. Parparov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

Fide Rating List is Copyright (C) by International Chess Federation
http://www.fide.com

=cut
