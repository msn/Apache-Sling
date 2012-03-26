#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 86;
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

# test group name:
my $test_group1 = "g-group_test_group_1_$$";
my $test_group2 = "g-group_test_group_2_$$";
my $test_group3 = "g-group_test_group_3_$$";
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
# Check viewing non-existent group:
ok( ! $group->view( "non-existent-$test_group1" ),
    "Group Test: check viewing non-existent group fails." );
# create groups:
ok( $group->add( $test_group1, \@test_properties ),
    "Group Test: Group \"$test_group1\" added successfully." );
ok( $group->check_exists( $test_group1 ),
    "Group Test: Group \"$test_group1\" exists." );
ok( $group->add( $test_group2, \@test_properties ),
    "Group Test: Group \"$test_group2\" added successfully." );
ok( $group->check_exists( $test_group2 ),
    "Group Test: Group \"$test_group2\" exists." );
ok( $group->add( $test_group3, \@test_properties ),
    "Group Test: Group \"$test_group3\" added successfully." );
ok( $group->check_exists( $test_group3 ),
    "Group Test: Group \"$test_group3\" exists." );

# Test creating group that already exists:
ok( ! $group->add( $test_group1, \@test_properties ),
    "Group Test: adding group that already exists fails." );

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

ok( ! $group->member_add( "non-existent-$test_group1", $test_user ),
    "Group Test: Unable to add member to non-existent group" );

# Test group member additions from file:
my $test_upload_user1 = "user_test_upload_user_1_$$";
my $test_upload_user2 = "user_test_upload_user_2_$$";
my $test_upload_user3 = "user_test_upload_user_3_$$";
my $test_upload_user4 = "user_test_upload_user_4_$$";

ok( $user->add( $test_upload_user1, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user1\" added successfully." );
ok( $user->add( $test_upload_user2, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user2\" added successfully." );
ok( $user->add( $test_upload_user3, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user3\" added successfully." );
ok( $user->add( $test_upload_user4, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user4\" added successfully." );

ok( $user->check_exists( $test_upload_user1 ),
    "Group Test: User \"$test_upload_user1\" exists." );
ok( $user->check_exists( $test_upload_user2 ),
    "Group Test: User \"$test_upload_user2\" exists." );
ok( $user->check_exists( $test_upload_user3 ),
    "Group Test: User \"$test_upload_user3\" exists." );
ok( $user->check_exists( $test_upload_user4 ),
    "Group Test: User \"$test_upload_user4\" exists." );

my $upload = "group,user\n$test_group3,$test_upload_user1";
ok( $group->member_add_from_file(\$upload,0,1), 'Check member_add_from_file function' );
$upload = "group,user\n$test_group3,$test_upload_user2\n$test_group3,$test_upload_user3\n$test_group3,$test_upload_user4";
ok( $group->member_add_from_file(\$upload,0,3), 'Check member_add_from_file function with three forks' );
$upload = "group,bad_heading\n$test_group3,$test_upload_user1";
throws_ok{ $group->member_add_from_file(\$upload,0,1); } qr%Second CSV column must be the user ID, column heading must be "user". Found: "bad_heading".%, 'Check member_add_from_file function with bad second heading';
$upload = "group,user\n$test_group3,$test_upload_user1,bad_extra_column";
throws_ok{ $group->member_add_from_file(\$upload,0,1); } qr%Found "3" columns. There should have been "2".%, 'Check member_add_from_file function with heading / data count mismatch';
$upload = "group,user,property\n$test_group3,$test_upload_user2,test";
ok( $group->member_add_from_file(\$upload,0,1), 'Check member_add_from_file function with extra property specified' );

ok( ! $group->member_view( "non-existent-$test_group1" ),
    "Group Test: Test for members in non-existent group." );
ok( ! $group->member_exists( "non-existent-$test_group1", $test_user ),
    "Group Test: Test member exists in non-existent group." );

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

# Testing group addition from file
# test group name:
my $test_upload_group1 = "group_test_upload_group_1_$$";
my $test_upload_group2 = "group_test_upload_group_2_$$";
my $test_upload_group3 = "group_test_upload_group_3_$$";
my $test_upload_group4 = "group_test_upload_group_4_$$";

$upload = "group\n$test_upload_group1";
ok( $group->add_from_file(\$upload,0,1), 'Check add_from_file function' );
$upload = "group\n$test_upload_group2\n$test_upload_group3\n$test_upload_group4";
ok( $group->add_from_file(\$upload,0,3), 'Check add_from_file function with three forks' );
$upload = "bad_heading\n$test_upload_group1";
throws_ok{ $group->add_from_file(\$upload,0,1); } qr%First CSV column must be the group ID, column heading must be "group". Found: "bad_heading".%, 'Check add_from_file function with bad heading';
$upload = "group\n$test_upload_group1,bad_extra_column";
throws_ok{ $group->add_from_file(\$upload,0,1); } qr%Found "2" columns. There should have been "1".%, 'Check add_from_file function with heading / data count mismatch';
$upload = "group,property\n$test_upload_group2,test";
ok( $group->add_from_file(\$upload,0,1), 'Check add_from_file function with extra property specified' );

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

ok( $user->del( $test_upload_user1, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user1\" deleted successfully." );
ok( $user->del( $test_upload_user2, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user2\" deleted successfully." );
ok( $user->del( $test_upload_user3, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user3\" deleted successfully." );
ok( $user->del( $test_upload_user4, $test_pass, \@test_properties ),
    "Group Test: User \"$test_upload_user4\" deleted successfully." );

ok( ! $user->check_exists( $test_upload_user1 ),
    "Group Test: User \"$test_upload_user1\" no longer exists." );
ok( ! $user->check_exists( $test_upload_user2 ),
    "Group Test: User \"$test_upload_user2\" no longer exists." );
ok( ! $user->check_exists( $test_upload_user3 ),
    "Group Test: User \"$test_upload_user3\" no longer exists." );
ok( ! $user->check_exists( $test_upload_user4 ),
    "Group Test: User \"$test_upload_user4\" no longer exists." );

# Cleanup Groups:
ok( $group->del( $test_group1 ),
    "Group Test: Group \"$test_group1\" deleted successfully." );
ok( $group->del( $test_group2 ),
    "Group Test: Group \"$test_group2\" deleted successfully." );
ok( $group->del( $test_group3 ),
    "Group Test: Group \"$test_group3\" deleted successfully." );
ok( $group->del( $test_upload_group1 ),
    "User Test: User \"$test_upload_group1\" deleted successfully." );
ok( $group->del( $test_upload_group2 ),
    "User Test: User \"$test_upload_group2\" deleted successfully." );
ok( ! $group->del( $test_upload_group3 ),
    "User Test: Deleting non-existent group fails." );
ok( $group->del( $test_upload_group4 ),
    "User Test: User \"$test_upload_group4\" deleted successfully." );
ok( ! $group->check_exists( $test_group1 ),
    "Group Test: Group \"$test_group1\" should no longer exist." );
ok( ! $group->check_exists( $test_group2 ),
    "Group Test: Group \"$test_group2\" should no longer exist." );
ok( ! $group->check_exists( $test_group3 ),
    "Group Test: Group \"$test_group3\" should no longer exist." );
ok( ! $group->check_exists( $test_upload_group1 ),
    "User Test: User \"$test_upload_group1\" should no longer exist." );
ok( ! $group->check_exists( $test_upload_group2 ),
    "User Test: User \"$test_upload_group2\" should no longer exist." );
ok( ! $group->check_exists( $test_upload_group4 ),
    "User Test: User \"$test_upload_group4\" should no longer exist." );
