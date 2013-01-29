use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Chess::FIDE',
	license             => 'perl',
	dist_author         => q{Roman M. Parparov <roman@parparov.com>},
	dist_version_from   => 'lib/Chess/FIDE.pm',
	build_requires => {
		'Test::More' => 0,
	},
	requires            => {
		'IO::Scalar'               => 0,
		'IO::String'               => 0,
		'IO::File'                 => 0,
		'LWP::UserAgent'           => 0,
		'Archive::Zip'             => 0,
		'Archive::Zip::MemberRead' => 0,
	},
	add_to_cleanup      => [ 'Chess-FIDE-*' ],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
