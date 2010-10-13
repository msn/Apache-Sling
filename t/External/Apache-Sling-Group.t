#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 44;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }
BEGIN { use_ok( 'Apache::Sling::Group' ); }

# test group name:
my $test_group1 = "g-group_test_group_1_$$";
my $test_group2 = "g-group_test_group_2_$$";
# test properties:
my @test_properties;

# test user name:
my $test_user = "group_test_user_$$";
# test user pass:
my $test_pass = "pass";
# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Apache::Sling::Authn->new( \$sling);
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';
# group object:
my $group = Apache::Sling::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Apache::Sling::Group', 'group';

# Run tests:
ok( defined $group,
    "Group Test: Sling Group Object successfully created." );
ok( defined $user,
    "Group Test: Sling User Object successfully created." );
# create groups:
ok( $group->add( $test_group1, \@test_properties ),
    "Group Test: Group \"$test_group1\" added successfully." );
ok( $group->check_exists( $test_group1 ),
    "Group Test: Group \"$test_group1\" exists." );
ok( $group->add( $test_group2, \@test_properties ),
    "Group Test: Group \"$test_group2\" added successfully." );
ok( $group->check_exists( $test_group2 ),
    "Group Test: Group \"$test_group2\" exists." );

# Add test user:
ok( $user->add( $test_user, $test_pass, \@test_properties ),
    "Group Test: User \"$test_user\" added successfully." );
ok( $user->check_exists( $test_user ),
    "Group Test: User \"$test_user\" exists." );
    
# Test Group Membership:
ok( $group->member_add( $test_group1, $test_user ),
    "Group Test: Member \"$test_user\" added to \"$test_group1\"." );
ok( $group->member_exists( $test_group1, $test_user ),
    "Group Test: Member \"$test_user\" exists in \"$test_group1\"." );
ok( $group->member_view( $test_group1 ) == 1,
    "Group Test: 1 Member in \"$test_group1\"." );

ok( $group->member_add( $test_group2, $test_user ),
    "Group Test: Member \"$test_user\" added to \"$test_group2\"." );
ok( $group->member_exists( $test_group2, $test_user ),
    "Group Test: Member \"$test_user\" exists in \"$test_group2\"." );
ok( $group->member_view( $test_group2 ) == 1,
    "Group Test: 1 Member in \"$test_group2\"." );

ok( $group->member_add( $test_group1, $test_group2 ),
    "Group Test: Member \"$test_group2\" added to \"$test_group1\"." );
ok( $group->member_exists( $test_group1, $test_group2 ),
    "Group Test: Member \"$test_group2\" exists in \"$test_group1\"." );
ok( $group->member_view( $test_group1 ) == 2,
    "Group Test: 2 Members in \"$test_group1\"." );

TODO: {
    local $TODO = "This should give an error, not a 200 as the group does _not_ get added!";
    ok( ! $group->member_add( $test_group2, $test_group1 ),
        "Group Test: Member \"$test_group1\" should not be added to \"$test_group2\"." );
}
ok( ! $group->member_exists( $test_group2, $test_group1 ),
    "Group Test: Member \"$test_group1\" should not exist in \"$test_group2\"." );
ok( $group->member_view( $test_group2 ) == 1,
    "Group Test: Still 1 Member in \"$test_group2\"." );

# Delete members from groups:
ok( $group->member_delete( $test_group1, $test_user ),
    "Group Test: Member \"$test_user\" deleted from \"$test_group1\"." );
ok( $group->member_exists( $test_group1, $test_user ),
    "Group Test: Member \"$test_user\" should still exist in \"$test_group1\"." );
ok( $group->member_view( $test_group1 ) == 2,
    "Group Test: 1 Member in \"$test_group1\"." );
ok( $group->member_delete( $test_group1, $test_group2 ),
    "Group Test: Member \"$test_user\" deleted from \"$test_group1\"." );
ok( ! $group->member_exists( $test_group1, $test_user ),
    "Group Test: Member \"$test_user\" no longer exists in \"$test_group1\"." );
ok( ! $group->member_exists( $test_group1, $test_group2 ),
    "Group Test: Member \"$test_group2\" no longer exists in \"$test_group1\"." );
ok( $group->member_view( $test_group1 ) == 0,
    "Group Test: 0 Members in \"$test_group1\"." );
ok( $group->member_delete( $test_group2, $test_user ),
    "Group Test: Member \"$test_user\" deleted from \"$test_group1\"." );
ok( ! $group->member_exists( $test_group2, $test_user ),
    "Group Test: Member \"$test_user\" no longer exists in \"$test_group2\"." );
ok( $group->member_view( $test_group2 ) == 0,
    "Group Test: 0 Members in \"$test_group2\"." );

# Cleanup Users:
ok( $user->del( $test_user ),
    "Group Test: User \"$test_user\" deleted successfully." );
ok( ! $user->check_exists( $test_user ),
    "Group Test: User \"$test_user\" no longer exists." );

# Cleanup Groups:
ok( $group->del( $test_group1 ),
    "Group Test: Group \"$test_group1\" deleted successfully." );
ok( ! $group->check_exists( $test_group1 ),
    "Group Test: Group \"$test_group1\" should no longer exist." );
ok( $group->del( $test_group2 ),
    "Group Test: Group \"$test_group2\" deleted successfully." );
ok( ! $group->check_exists( $test_group2 ),
    "Group Test: Group \"$test_group2\" should no longer exist." );
