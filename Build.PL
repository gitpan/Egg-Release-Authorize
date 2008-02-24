use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Release::Authorize',
  dist_version_from => 'lib/Egg/Release/Authorize.pm',
  dist_abstract     => 'lib/Egg/Release/Authorize.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {

    'Egg::Release'            => '3.01',
    'Egg::Plugin::SessionKit' => '3.02',
    'Egg::Release::DBI'       => '0.02',
    'Egg::Release::DBIC'      => '0.02',
    'Digest::MD5'             => '2.36',
    'Digest::SHA1'            => '2.11',
    'Crypt::CBC'              => '2.24',
    'Crypt::Blowfish'         => '2.10',
    'Crypt::DES'              => '2.05',
    'Crypt::Camellia'         => '2.01',
    'Cache::Cache'            => '1.05',

    'Test::More'           => 0,
    'Test::Pod'            => 0,
    'Test::Perl::Critic'   => 0,
    'Test::Pod::Coverage'  => 0,
    },

  );

$builder->create_build_script();
