# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok( 'Apache::Sling::Print' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok( Apache::Sling::Print::print_lock('Check print_lock function'), 'Check print_lock function' );
ok( Apache::Sling::Print::print_with_lock('Check print_with_lock function'), 'Check print_with_lock function' );
