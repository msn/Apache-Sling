# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $authn   = new Apache::Sling::Authn('http://localhost:8080',undef,undef,'basic','1','log.txt');
my $user = new Apache::Sling::User(\$authn,'1','log.txt');
ok( $user->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $user->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $user->{ 'Message' } eq '',                      'Check Message set' );
ok( $user->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $user->{ 'Authn' },                      'Check authn defined' );
ok( defined $user->{ 'Response' },                   'Check response defined' );

$user->set_results( 'Test Message', undef );
ok( $user->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $user->{ 'Response' },          'Check response no longer defined' );
