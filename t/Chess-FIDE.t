# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chess-FIDE.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Chess::FIDE'); };

our $localfile = 'APR04FRL.TXT';
our $fide;

ok($fide = &local_file(),'local file');
ok($fide = &remote_file(),'remote file');
ok(&simple_search(),'simple search');
ok(&complex_search(),'complex search');
sub local_file {

    my $fide = Chess::FIDE->new(-file=>$localfile);
    return $fide;
}
sub remote_file {

    my $fide = Chess::FIDE->new(-www=>1,
				-proxy=>'http://proxy.tau.ac.il:8080');
    return $fide;
}
sub simple_search {

    my @result = $fide->fideSearch("surname eq 'Kramnik'");
    return $#result == 0;
}
sub complex_search {

    my @result = $fide->fideSearch("surname =~ /Kasparov/ && name =~ /Garry/");
    return $#result == 0;

}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

