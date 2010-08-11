use Test::More tests => 11;
BEGIN { use_ok( 'Apache::Sling::ContentUtil' ); }

my @properties = '';
ok( Apache::Sling::ContentUtil::add_setup( 'http://localhost:8080', 'remote/', \@properties) eq
  'post http://localhost:8080/remote/ $post_variables = []', 'Check add_setup function' );
push @properties, "a=b";
ok( Apache::Sling::ContentUtil::add_setup( 'http://localhost:8080', 'remote/', \@properties) eq
  "post http://localhost:8080/remote/ \$post_variables = ['a','b']", 'Check add_setup function with variables' );
ok( Apache::Sling::ContentUtil::copy_setup('http://localhost:8080','remoteSrc/', 'remoteDest/') eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','copy']", 'Check copy_setup function without replace defined' );
ok(Apache::Sling::ContentUtil::copy_setup('http://localhost:8080','remoteSrc/','remoteDest/',1) eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','copy',':replace','true']", 'Check copy_setup function with replace defined' );
ok(Apache::Sling::ContentUtil::delete_setup('http://localhost:8080','remote/') eq
  "post http://localhost:8080/remote/ \$post_variables = [':operation','delete']", 'Check delete_setup function' );
ok(Apache::Sling::ContentUtil::exists_setup('http://localhost:8080','remote') eq
  "get http://localhost:8080/remote.json", 'Check exists_setup function' );
ok( Apache::Sling::ContentUtil::move_setup('http://localhost:8080','remoteSrc/', 'remoteDest/') eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','move']", 'Check move_setup function without replace defined' );
ok(Apache::Sling::ContentUtil::move_setup('http://localhost:8080','remoteSrc/','remoteDest/',1) eq
  "post http://localhost:8080/remoteSrc/ \$post_variables = [':dest','remoteDest/',':operation','move',':replace','true']", 'Check move_setup function with replace defined' );
ok(Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080','./local','remote','') eq
  "fileupload http://localhost:8080/remote ./* ./local \$post_variables = []", 'Check upload_file_setup function' );
ok(Apache::Sling::ContentUtil::upload_file_setup('http://localhost:8080','./local','remote','file') eq
  "fileupload http://localhost:8080/remote file ./local \$post_variables = []", 'Check upload_file_setup function' );
