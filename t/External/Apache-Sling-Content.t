#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 37;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

use File::Temp;
BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

# test content name:
my $test_content1 = "content_test_content_1_$$";
my $test_content2 = "content_test_content_2_$$";
my $test_content3 = "content_test_content_3_$$";
# test properties:
my @test_properties;
# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
# content object:
my $content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';

# Run tests:
ok( $content->add( $test_content1, \@test_properties ),
    "Content Test: Content \"$test_content1\" added successfully." );
ok( $content->check_exists( $test_content1 ),
    "Content Test: Content \"$test_content1\" exists." );
ok( ! $content->check_exists( "missing_$test_content1" ),
    "Content Test: Content \"missing_$test_content1\" should not exist." );

# Check copying:
ok( $content->copy( $test_content1, $test_content2 ),
    "Content Test: Content \"$test_content1\" copied to \"$test_content2\"." );
ok( $content->check_exists( $test_content2 ),
    "Content Test: Content \"$test_content2\" exists." );
ok( ! $content->copy( $test_content1, $test_content2 ),
    "Content Test: Can't copy content \"$test_content1\" to \"$test_content2\" without :replace." );
ok( $content->copy( $test_content1, $test_content2, 1 ),
    "Content Test: Can copy content \"$test_content1\" to \"$test_content2\" with :replace." );
ok( $content->check_exists( $test_content1 ),
    "Content Test: Content \"$test_content1\" exists." );
ok( $content->check_exists( $test_content2 ),
    "Content Test: Content \"$test_content2\" exists." );

# Check moving:
ok( $content->move( $test_content2, $test_content3 ),
    "Content Test: Content \"$test_content2\" moved to \"$test_content3\"." );
ok( $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" exists." );
ok( ! $content->check_exists( $test_content2 ),
    "Content Test: Content \"$test_content2\" no longer exists." );
ok( ! $content->move( $test_content1, $test_content3 ),
    "Content Test: Can't move content \"$test_content1\" to \"$test_content3\" without :replace." );
TODO: {
    local $TODO = "https://issues.apache.org/jira/browse/SLING-1648";
    ok( $content->move( $test_content1, $test_content3, 1 ),
        "Content Test: Can move content \"$test_content1\" to \"$test_content3\" with :replace." );
    ok( ! $content->check_exists( $test_content1 ),
        "Content Test: Content \"$test_content1\" no longer exists." );
}
ok( $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" exists." );

# Cleanup
# Remove this following delete when move with :replace starts working!
ok( $content->del( $test_content1 ),
    "Content Test: Content \"$test_content1\" deleted successfully." );
ok( $content->del( $test_content3 ),
    "Content Test: Content \"$test_content3\" deleted successfully." );
ok( ! $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" should no longer exist." );

# Test uploading:
# authn object:
$authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
# content object:
$content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';

# Check upload with non-logged in user:
my ( $tmp_content_handle, $tmp_content_name ) = File::Temp::tempfile();
print {$tmp_content_handle} "Test file\n";
ok ( $content->upload_file($tmp_content_name,$test_content1), 'Check upload_file function when not logged in' );
ok( $content->del( $test_content1 ),
    "Content Test: Content \"$test_content1\" deleted successfully." );
unlink($tmp_content_name);

# Recreate objects with user / pass set:
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;

# authn object:
$authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
# content object:
$content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';

( $tmp_content_handle, $tmp_content_name ) = File::Temp::tempfile();
print {$tmp_content_handle} "Test file\n";
ok( $content->upload_file($tmp_content_name,$test_content1), 'Check upload_file function' );
my $upload = "$tmp_content_name,$test_content1\n";
ok( $content->upload_from_file(\$upload,0,1), 'Check upload_from_file function' );
my ( $tmp_content2_handle, $tmp_content2_name ) = File::Temp::tempfile();
$upload .= "$tmp_content2_name,$test_content2\n";
ok( $content->upload_from_file(\$upload,1,2), 'Check upload_from_file function with two forks' );
unlink($tmp_content_name);
unlink($tmp_content2_name);
throws_ok{ $content->upload_from_file($tmp_content_name,0,1)} qr{Problem opening file: '$tmp_content_name'}, 'Check upload_file function croaks with a missing file';
ok( $content->del( $test_content1 ),
    "Content Test: Content \"$test_content1\" deleted successfully." );
ok( $content->del( $test_content2 ),
    "Content Test: Content \"$test_content2\" deleted successfully." );
