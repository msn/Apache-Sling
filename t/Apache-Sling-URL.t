# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Apache-Sling.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok( 'Apache::Sling::URL' ); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok( Apache::Sling::URL::add_leading_slash( 'value' ) eq '/value', 'Check add_leading_slash function' );
ok( Apache::Sling::URL::add_leading_slash( '/value' ) eq '/value', 'Check add_leading_slash function' );
ok( Apache::Sling::URL::strip_leading_slash( 'value' ) eq 'value', 'Check add_leading_slash function' );
ok( Apache::Sling::URL::strip_leading_slash( '/value' ) eq 'value', 'Check add_leading_slash function' );
my @properties;
ok( Apache::Sling::URL::properties_array_to_string( \@properties ) eq '', 'Check properties_array_to_string function empty array' );
@properties = ('a=b');
ok( Apache::Sling::URL::properties_array_to_string( \@properties ) eq "'a','b'", 'Check properties_array_to_string function 1 item' );
push @properties, "c\'=d";
ok( Apache::Sling::URL::properties_array_to_string( \@properties ) eq "'a','b','c\\'','d'", 'Check properties_array_to_string function 2 items' );
ok( Apache::Sling::URL::urlencode( "'%^&*" ) eq '%27%25%5E%26%2A', 'Check urlencode function' );
ok( Apache::Sling::URL::url_input_sanitize() eq 'http://localhost:8080', 'Check url_input_sanitize function undefined' );
ok( Apache::Sling::URL::url_input_sanitize('') eq 'http://localhost:8080', 'Check url_input_sanitize function empty' );
ok( Apache::Sling::URL::url_input_sanitize('http://localhost:8080/') eq 'http://localhost:8080', 'Check url_input_sanitize function trailing slash' );
ok( Apache::Sling::URL::url_input_sanitize('localhost:8080/') eq 'http://localhost:8080', 'Check url_input_sanitize function trailing slash and http' );
