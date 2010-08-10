# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok( 'Apache::Sling::AuthnUtil' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok( Apache::Sling::AuthnUtil::basic_login_setup( 'http://localhost:8080' ) eq
  'get http://localhost:8080/system/sling/login?sling:authRequestLogin=1', 'Check basic_login_setup function' );
