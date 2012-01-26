#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 32;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }
BEGIN { use_ok( 'Apache::Sling::Group' ); }

# test user name:
my $test_user = "user_test_user_$$";
# test user pass:
my $test_pass = "pass";
# test user new pass:
my $test_pass_new = "passnew";
# test properties:
my @test_properties;

# test group name:
my $test_group = "g-user_test_group_$$";

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;

# Check error is thrown without auth:
throws_ok{ my $user = Apache::Sling::User->new(); } qr%no authn provided!%, 'Check user creation croaks with authn missing';

# authn object:
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';
# group object:
my $group = Apache::Sling::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Apache::Sling::Group', 'group';

# Run tests:
ok( defined $user,
    "User Test: Sling User Object successfully created." );
ok( defined $group,
    "User Test: Sling Group Object successfully created." );

# add user:
ok( $user->add( $test_user, $test_pass, \@test_properties ),
    "User Test: User \"$test_user\" added successfully." );
ok( $user->check_exists( $test_user ),
    "User Test: User \"$test_user\" exists." );

# Check can update properties:
@test_properties = ( "user_test_editor=$super_user" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );

# Check can update properties after addition pf user to group:
# http://jira.sakaiproject.org/browse/KERN-270
# create group:
ok( $group->add( $test_group, \@test_properties ),
    "User Test: Group \"$test_group\" added successfully." );
ok( $group->check_exists( $test_group ),
    "User Test: Group \"$test_group\" exists." );
# Add member to group:
ok( $group->member_add( $test_group, $test_user ),
    "User Test: Member \"$test_user\" added to \"$test_group\"." );
ok( $group->member_exists( $test_group, $test_user ),
    "User Test: Member \"$test_user\" exists in \"$test_group\"." );
# Check can still update properties:
@test_properties = ( "user_test_edit_after_group_join=true" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );
# Delete test user from group:
ok( $group->member_delete( $test_group, $test_user ),
    "User Test: Member \"$test_user\" deleted from \"$test_group\"." );
ok( ! $group->member_exists( $test_group, $test_user ),
    "User Test: Member \"$test_user\" should no longer exist in \"$test_group\"." );
# Cleanup Group:
ok( $group->del( $test_group ),
    "User Test: Group \"$test_group\" deleted successfully." );
ok( ! $group->check_exists( $test_group ),
    "User Test: Group \"$test_group\" should no longer exist." );

# Switch to test_user
ok( $authn->switch_user( $test_user, $test_pass ),
    "User Test: Successfully switched to user: \"$test_user\" with basic auth" );

# Check can update properties:
@test_properties = ( "user_test_editor=$test_user" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );

# switch back to admin user:
ok( $authn->switch_user( $super_user, $super_pass ),
    "User Test: Successfully switched to user: \"$super_user\" with basic auth" );

# Change user's password:
ok( $user->change_password( $test_user, $test_pass, $test_pass_new, $test_pass_new ),
    "User Test: Successfully changed password from \"$test_pass\" to \"$test_pass_new\" for user: \"$test_user\"");

# Switch to test_user with new pass:
ok( $authn->switch_user( $test_user, $test_pass_new ),
    "User Test: Successfully switched to user: \"$test_user\" with basic auth and new pass" );

# switch back to admin user:
ok( $authn->switch_user( $super_user, $super_pass ),
    "User Test: Successfully switched to user: \"$super_user\" with basic auth" );

# Testing view for user:
ok( $user->view( $test_user ),
    "User Test: User \"$test_user\" viewed successfully." );

# Check user deletion:
ok( $user->del( $test_user ),
    "User Test: User \"$test_user\" deleted successfully." );
ok( ! $user->check_exists( $test_user ),
    "User Test: User \"$test_user\" should no longer exist." );
