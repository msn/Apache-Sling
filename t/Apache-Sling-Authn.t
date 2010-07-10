# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok( 'Apache::Sling::Authn' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $authn = new Apache::Sling::Authn('http://localhost:8080',undef,undef,'basic','0','log.txt');
ok( $authn->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
