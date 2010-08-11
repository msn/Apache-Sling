#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 22;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

# test content name:
my $test_content1 = "content_test_content_1_$$";
my $test_content2 = "content_test_content_2_$$";
my $test_content3 = "content_test_content_3_$$";
# test properties:
my @test_properties;
# authn object:
my $authn = Apache::Sling::Authn->new( $sling_host, $super_user, $super_pass, 'basic', $verbose, $log );
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
ok( $content->move( $test_content1, $test_content3, 1 ),
    "Content Test: Can move content \"$test_content1\" to \"$test_content3\" with :replace." );
ok( $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" exists." );
ok( ! $content->check_exists( $test_content1 ),
    "Content Test: Content \"$test_content2\" no longer exists." );

# Cleanup
ok( $content->del( $test_content3 ),
    "Content Test: Content \"$test_content3\" deleted successfully." );
ok( ! $content->check_exists( $test_content3 ),
    "Content Test: Content \"$test_content3\" should no longer exist." );
