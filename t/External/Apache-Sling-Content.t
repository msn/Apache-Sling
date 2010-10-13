#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 25;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

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
