# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok( 'Apache::Sling::GroupUtil' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @properties = '';
ok( Apache::Sling::GroupUtil::add_setup( 'http://localhost:8080', 'group', \@properties) eq
  "post http://localhost:8080/system/userManager/group.create.html \$postVariables = [':name','group']", 'Check add_setup function' );
push @properties, "a=b";
ok( Apache::Sling::GroupUtil::add_setup( 'http://localhost:8080', 'group', \@properties) eq
  "post http://localhost:8080/system/userManager/group.create.html \$postVariables = [':name','group','a','b']", 'Check add_setup function with variables' );
