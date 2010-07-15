# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $authn   = new Apache::Sling::Authn('http://localhost:8080',undef,undef,'basic','1','log.txt');
my $content = new Apache::Sling::Content(\$authn,'1','log.txt');
ok( $content->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $content->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $content->{ 'Message' } eq '',                      'Check Message set' );
ok( $content->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $content->{ 'Authn' },                      'Check authn defined' );
ok( defined $content->{ 'Response' },                   'Check response defined' );

$content->set_results( 'Test Message', undef );
ok( $content->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $content->{ 'Response' },          'Check response no longer defined' );
