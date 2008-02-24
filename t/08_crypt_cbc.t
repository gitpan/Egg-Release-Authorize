use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;
use UNIVERSAL::require;

unless ( Cache::FileCache->require ) {
	plan skip_all=> "Cache::FileCache is not installed."
} else {
	unless ( Crypt::CBC->require ) {
		plan skip_all=> "Crypt::CBC is not installed."
	} else {
		test();
	}
}

sub test {

my $ciper= Crypt::Blowfish->require ? 'Blowfish'
         : Crypt::DES->require      ? 'DES'
         : Crypt::Camellia->require ? 'Camellia'
         : Crypt::Rabbit->require   ? 'Rabbit'
         : Crypt::Twofish2->require ? 'Twofish2'
         : return do {
	plan skip_all=> "The Ciper module is not installed.";
  };

plan tests=> 39;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";
my $psw    = '%test%';
my $key    = '12345678';
my $salt   = '';
my $passwd = do {
	my $cbc= Crypt::CBC->new({
	  cipher         => $ciper,
	  key            => $key,
	  iv             => '$KJh#(}q',
	  padding        => 'standard',
	  prepend_iv     => 0,
	  regenerate_key => 1,
	  });
	$cbc->encrypt_hex($psw. $salt);
  };

$tool->helper_create_files(
  [ $tool->helper_yaml_load( join('', <DATA>)) ],
  { path => $path, salt=> $salt, cipher=> $ciper, key=> $key, passwd=> $passwd },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { MODEL=> ['Auth'] },
  });

ok $e->is_model('auth'), q{$e->is_model('auth')};
ok $e->is_model('a_test'), q{$e->is_model('a_test')};

ok my $s= $e->model('a_test'), q{$s= $e->model('a_test')};
is $s, $e->model('auth'), q{$s, $e->model('auth')};

isa_ok $s, 'Vtest::Model::Auth::Test';
isa_ok $s, 'Egg::Model::Auth::Session::FileCache';
isa_ok $s, 'Egg::Model::Auth::Bind::Cookie';
isa_ok $s, 'Egg::Model::Auth::Base';
isa_ok $s, 'Egg::Base';
isa_ok $s, 'Egg::Component';
isa_ok $s, 'Egg::Component::Base';

ok my $a= $s->api, q{my $a= $s->api};
isa_ok $a, 'Vtest::Model::Auth::Test::API::File';
isa_ok $a, 'Egg::Model::Auth::Crypt::CBC';
isa_ok $a, 'Egg::Model::Auth::Base::API';
isa_ok $a, 'Egg::Component::Base';

$e->helper_create_dir($e->path_to('cache'));

##
can_ok $a, 'create_password';
  is $a->create_password($psw), $passwd, qq{$a->create_password('$psw')};
##

my $param= $e->request->params;
$param->{__uid}= 'tester1';
$param->{__psw}= $psw;

can_ok $s, 'login_check';
  ok my $data= $s->login_check, q{my $data= $s->login_check};
  isa_ok $data, 'HASH';

can_ok $s, 'data';
  is $data, $s->data, q{$data, $s->data};
  is $data->{___api_name}, 'file', q{$data->{___api_name}, 'file'};
  is $data->{___user}, 'tester1', q{$data->{___user}, 'tester1'};
  is $data->{___password}, $passwd, q{$data->{___password}, $passwd};
  is $data->{___active}, 1, q{$data->{___active}, 1};
  is $data->{___group}, 'admin', q{$data->{___group}, 'admin'};
  is $data->{age}, 20, q{$data->{age}, 20};

ok my $cookie= $e->response->cookies->{as}, q{my $cookie= $e->response->cookies->{as}};
  is $cookie->value, $s->session_id, q{$cookie->value, $s->session_id};

can_ok $s, 'is_login';
  ok $s->is_login, q{$s->is_login};
  is $data, $s->is_login, q{$data, $s->is_login};

can_ok $s, 'group_check';
  ok $s->group_check('admin'), q{$s->group_check('admin')};

can_ok $s, 'logout';
  ok $s->logout, q{$s->logout};
  ok ! $s->is_login, q{! $s->is_login};

}

__DATA__
---
filename: <e.path>/lib/Vtest/Model/Auth/Test.pm
value: |
  package Vtest::Model::Auth::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Auth::Base /;
  
  __PACKAGE__->config(
    label_name    => 'a_test',
    login_get_ok  => 1,
    crypt_cbc_salt=> '<e.salt>',
    crypt_cbc => {
      cipher => '<e.cipher>',
      key    => '<e.key>',
      },
    file=> {
      path   => Vtest->path_to(qw/ etc members /),
      fields => [qw/ uid psw active a_group age /],
      id_field       => 'uid',
      password_field => 'psw',
      active_field   => 'active',
      group_field    => 'a_group',
      delimiter      => qr{ *\t *},
      },
    );
  
  __PACKAGE__->setup_session( FileCache => 'Bind::Cookie' );
  
  __PACKAGE__->setup_api( File => 'Crypt::CBC' );
  
  1;
---
filename: <e.path>/etc/members
value: |
  tester1	<e.passwd>	1	admin	20
  tester2		1	users	21
  tester3	<e.passwd>	0	users	22
  tester4	<e.passwd>	1	users	23
