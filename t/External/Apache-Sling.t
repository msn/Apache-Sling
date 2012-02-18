#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 9;

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

# Add content item to manipulate:
ok( $content->add( $test_content1 ),
    "Sling Test: Content \"$test_content1\" added successfully." );

ok( my $authz_config = $sling->authz_config, 'check authz_config function' );

ok( $sling->authz_run($authz_config), 'check authz_run function' );

# Cleanup
# Remove this following delete when move with :replace starts working!
ok( $content->del( $test_content1 ),
    "Sling Test: Content \"$test_content1\" deleted successfully." );
ok( ! $content->check_exists( $test_content1 ),
    "Sling Test: Content \"$test_content1\" should no longer exist." );
