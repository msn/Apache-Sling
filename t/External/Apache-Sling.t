#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 21;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

# test content name:
my $test_content1 = "content_test_content_1_$$";
# test user name:
my $test_user = "user_test_user_$$";
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
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
# content object:
my $content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';

# Add content item to manipulate:
ok( $content->add( $test_content1 ),
    "Sling Test: Content \"$test_content1\" added successfully." );

# add user:
ok( $user->add( $test_user, $test_pass ),
    "Sling Test: User \"$test_user\" added successfully." );

ok( my $authz_config = $sling->authz_config, 'check authz_config function' );

ok( $sling->authz_run($authz_config), 'check authz_run function' );

$authz_config->{'write'} = \1;
$authz_config->{'read'} = \1;
$authz_config->{'addChildNodes'} = \1;
$authz_config->{'delete'} = \1;
$authz_config->{'lifecycleManage'} = \1;
$authz_config->{'lockManage'} = \1;
$authz_config->{'modifyACL'} = \1;
$authz_config->{'modifyProps'} = \1;
$authz_config->{'nodeTypeManage'} = \1;
$authz_config->{'readACL'} = \1;
$authz_config->{'removeChilds'} = \1;
$authz_config->{'removeNode'} = \1;
$authz_config->{'retentionManage'} = \1;
$authz_config->{'versionManage'} = \1;
$authz_config->{'view'} = \1;
$authz_config->{'removeNode'} = \1;
$authz_config->{'remote'} = \$test_content1;
$authz_config->{'principal'} = \$test_user;

ok( $sling->authz_run($authz_config), q{check authz_run function adding permissions to $test_content1 for $test_user} );

$authz_config->{'write'} = \0;
$authz_config->{'read'} = \0;
$authz_config->{'addChildNodes'} = \0;
$authz_config->{'delete'} = \0;
$authz_config->{'lifecycleManage'} = \0;
$authz_config->{'lockManage'} = \0;
$authz_config->{'modifyACL'} = \0;
$authz_config->{'modifyProps'} = \0;
$authz_config->{'nodeTypeManage'} = \0;
$authz_config->{'readACL'} = \0;
$authz_config->{'removeChilds'} = \0;
$authz_config->{'removeNode'} = \0;
$authz_config->{'retentionManage'} = \0;
$authz_config->{'versionManage'} = \0;
$authz_config->{'view'} = \0;
$authz_config->{'removeNode'} = \0;

ok( $sling->authz_run($authz_config), q{check authz_run function removing permissions from $test_content1 for $test_user} );

ok( $authz_config = $sling->authz_config, 'check authz_config function' );

$authz_config->{'all'} = \1;
$authz_config->{'remote'} = \$test_content1;
$authz_config->{'principal'} = \$test_user;

ok( $sling->authz_run($authz_config), q{check authz_run function adding all permissions to $test_content1 for $test_user} );

$authz_config->{'all'} = \0;

ok( $sling->authz_run($authz_config), q{check authz_run function removing all permissions from $test_content1 for $test_user} );

# Cleanup
ok( $content->del( $test_content1 ),
    "Sling Test: Content \"$test_content1\" deleted successfully." );
ok( ! $content->check_exists( $test_content1 ),
    "Sling Test: Content \"$test_content1\" should no longer exist." );
ok( $user->del( $test_user ),
    "Sling Test: User \"$test_user\" deleted successfully." );
ok( ! $user->check_exists( $test_user ),
    "Sling Test: User \"$test_user\" should no longer exist." );
