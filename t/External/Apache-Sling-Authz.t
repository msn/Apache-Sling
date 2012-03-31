#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Authz' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

# test user name:
my $test_user = "user_test_user_$$";
# test user pass:
my $test_pass = "pass";

# test content name:
my $test_content1 = "content_test_content_1_$$";
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
ok( $authn->login_user(), "log in successful" );
# content object:
my $content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';
# authz object:
my $authz = Apache::Sling::Authz->new( \$authn, $verbose, $log );
isa_ok $authz, 'Apache::Sling::Authz', 'authz';
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';

# Run tests:
ok( $content->add( $test_content1, \@test_properties ),
    "Content Test: Content \"$test_content1\" added successfully." );

ok ( ! $authz->get_acl( 'bad_content_does_not_exist' ), 'Check get_acl function with bad content location' );

ok( $authz->get_acl( $test_content1 ),
    "Authz Test: Content \"$test_content1\" ACL fetched successfully." );

my @grant_privileges;
my @deny_privileges;

# add user:
ok( $user->add( $test_user, $test_pass ),
    "User Test: User \"$test_user\" added successfully." );

ok( $authz->modify_privileges( $test_content1, $test_user, \@grant_privileges, \@deny_privileges ),
    "Authz Test: Content \"$test_content1\" ACL privileges successfully modified." );

ok( ! $authz->modify_privileges( 'bad_content_does_not_exist', $test_user, \@grant_privileges, \@deny_privileges ),
    "Authz Test: Content \"bad_content_does_not_exist\" ACL privileges not modified." );

push @grant_privileges, 'read';

ok( $authz->modify_privileges( $test_content1, $test_user, \@grant_privileges, \@deny_privileges ),
    "Authz Test: Content \"$test_content1\" ACL privileges successfully modified." );

ok( ! $authz->del( 'bad_content_does_not_exist', $test_user ),
    "Authz Test: Content \"bad_content_does_not_exist\" ACL privileges not removed for principal: \"$test_user\"." );

ok( $authz->del( $test_content1, $test_user ),
    "Authz Test: Content \"$test_content1\" ACL privileges successfully removed for principal: \"$test_user\"." );

ok( $user->del( $test_user ),
    "User Test: User \"$test_user\" deleted successfully." );

ok( $content->del( $test_content1 ),
    "Content Test: Content \"$test_content1\" deleted successfully." );
