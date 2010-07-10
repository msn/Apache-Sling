# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok( 'Apache::Sling::AuthnUtil' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok( Apache::Sling::AuthnUtil::basic_login_setup( 'http://localhost:8080' ) eq
  'get http://localhost:8080/system/sling/login?sling:authRequestLogin=1', 'Check basic_login_setup function' );

ok( Apache::Sling::AuthnUtil::form_login_setup( 'http://localhost:8080', 'admin', 'admin') eq
  q(post http://localhost:8080/system/sling/formlogin $postVariables = ['sakaiauth:un','admin','sakaiauth:pw','admin','sakaiauth:login','1']),
  'Check form_login_setup function' );

ok( Apache::Sling::AuthnUtil::form_logout_setup( 'http://localhost:8080' ) eq
  q(post http://localhost:8080/system/sling/formlogin $postVariables = ['sakaiauth:logout','1']), 'Check form_logout_setup function' );
