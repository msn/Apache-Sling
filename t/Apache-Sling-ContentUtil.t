# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok( 'Apache::Sling::ContentUtil' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @properties = '';
ok( Apache::Sling::ContentUtil::add_setup( 'http://localhost:8080', 'remote/', \@properties) eq
  'post http://localhost:8080/remote/ $postVariables = []', 'Check add_setup function' );
push @properties, "a=b";
ok( Apache::Sling::ContentUtil::add_setup( 'http://localhost:8080', 'remote/', \@properties) eq
  "post http://localhost:8080/remote/ \$postVariables = ['a','b']", 'Check add_setup function with variables' );
ok( Apache::Sling::ContentUtil::copy_setup('http://localhost:8080','remoteSrc/', 'remoteDest/') eq
  "post http://localhost:8080/remoteSrc/ \$postVariables = [':dest','remoteDest/',':operation','copy']", 'Check copy_setup function without replace defined' );
ok(Apache::Sling::ContentUtil::copy_setup('http://localhost:8080','remoteSrc/','remoteDest/',1) eq
  "post http://localhost:8080/remoteSrc/ \$postVariables = [':dest','remoteDest/',':operation','copy',':replace','true']", 'Check copy_setup function with replace defined' );
ok(Apache::Sling::ContentUtil::delete_setup('http://localhost:8080','remote/') eq
  "post http://localhost:8080/remote/ \$postVariables = [':operation','delete']", 'Check delete_setup function' );
ok(Apache::Sling::ContentUtil::exists_setup('http://localhost:8080','remote') eq
  "get http://localhost:8080/remote.json", 'Check exists_setup function' );
ok( Apache::Sling::ContentUtil::move_setup('http://localhost:8080','remoteSrc/', 'remoteDest/') eq
  "post http://localhost:8080/remoteSrc/ \$postVariables = [':dest','remoteDest/',':operation','move']", 'Check move_setup function without replace defined' );
ok(Apache::Sling::ContentUtil::move_setup('http://localhost:8080','remoteSrc/','remoteDest/',1) eq
  "post http://localhost:8080/remoteSrc/ \$postVariables = [':dest','remoteDest/',':operation','move',':replace','true']", 'Check move_setup function with replace defined' );
ok(Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080','./local','remote','') eq
  "fileupload http://localhost:8080/remote ./* ./local \$postVariables = []", 'Check upload_file_setup function' );
ok(Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080','./local','remote','file') eq
  "fileupload http://localhost:8080/remote file ./local \$postVariables = []", 'Check upload_file_setup function' );
