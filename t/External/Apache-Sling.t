#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 78;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

use File::Temp;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }
BEGIN { use_ok( 'Apache::Sling::Group' ); }
BEGIN { use_ok( 'Apache::Sling::JsonQueryServlet' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

################################################################################
# Testing Content:

# test content name:
my $test_content1 = "content_test_content_1_$$";
my $test_content2 = "content_test_content_2_$$";
my $test_content3 = "content_test_content_3_$$";
# test group name:
my $test_group1 = "group_test_group_1_$$";
# test user name:
my $test_user = "user_test_user_$$";
# test user pass:
my $test_pass1 = "pass1";
my $test_pass2 = "pass2";

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
my $group = Apache::Sling::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Apache::Sling::Group', 'group';
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';

# Add content item to manipulate:
ok( my $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'add'} = \$test_content1;
$content_config->{'remote'} = \$test_content1;
ok( $sling->content_run($content_config), q{check content_run function adding content $test_content1} );

# Test content additions from file:
my ( $tmp_content_additions_handle, $tmp_content_additions_name ) = File::Temp::tempfile();
ok( $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'additions'} = \$tmp_content_additions_name;
ok( $sling->content_run($content_config), q{check content_run function additions} );
unlink( $tmp_content_additions_name ); 

# Test viewing content:
ok( $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'view'} = \1;
$content_config->{'remote'} = \$test_content1;
ok( $sling->content_run($content_config), q{check content_run function viewing content $test_content1} );

# add user:

ok( my $user_config = $sling->user_config, 'check user_config function' );
$user_config->{'add'} = \$test_user;
$user_config->{'email'} = \"test\@example.com";
$user_config->{'first-name'} = \"test";
$user_config->{'last-name'} = \"test";
$user_config->{'password'} = \$test_pass1;
ok( $sling->user_run($user_config), q{check user_run function adding user $test_user} );

ok( $user_config = $sling->user_config, 'check user_config function' );
$user_config->{'exists'} = \$test_user;
ok( $sling->user_run($user_config), q{check user_run function check exists user $test_user} );

ok( $user_config = $sling->user_config, 'check user_config function' );
$user_config->{'view'} = \$test_user;
ok( $sling->user_run($user_config), q{check user_run function view user $test_user} );

ok( $user_config = $sling->user_config, 'check user_config function' );
$user_config->{'update'} = \$test_user;
ok( $sling->user_run($user_config), q{check user_run function update user $test_user} );

ok( $user_config = $sling->user_config, 'check user_config function' );
$user_config->{'change-password'} = \$test_user;
$user_config->{'password'} = \$test_pass1;
$user_config->{'new-password'} = \$test_pass2;
ok( $sling->user_run($user_config), q{check user_run function update user $test_user} );

my ( $tmp_user_additions_handle, $tmp_user_additions_name ) = File::Temp::tempfile();
ok( $user_config = $sling->user_config, 'check user_config function' );
$user_config->{'additions'} = \$tmp_user_additions_name;
ok( $sling->user_run($user_config), q{check user_run function additions} );
unlink( $tmp_user_additions_name ); 

# JSON Query Servlet
ok( my $json_query_servlet_config = $sling->json_query_servlet_config, 'check json_query_servlet_config function' );
$json_query_servlet_config->{'all_nodes'} = \1;
ok( $sling->json_query_servlet_run($json_query_servlet_config), 'check json_query_servlet_run function' );

# Authz:
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

# Test copying and moving content:
ok( $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'copy'} = \1;
$content_config->{'remote-source'} = \$test_content1;
$content_config->{'remote'} = \$test_content2;
ok( $sling->content_run($content_config), q{check content_run function copying content $test_content1 to $test_content2} );

ok( $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'move'} = \1;
$content_config->{'remote-source'} = \$test_content2;
$content_config->{'remote'} = \$test_content3;
ok( $sling->content_run($content_config), q{check content_run function moving content $test_content2 to $test_content1} );

# Test uploading file:
my ( $tmp_content_handle, $tmp_content_name ) = File::Temp::tempfile();
ok( $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'local'} = \$tmp_content_name;
ok( $sling->content_run($content_config), q{check content_run function with only local defined} );
$content_config->{'remote'} = \$test_content2;
ok( $sling->content_run($content_config), q{check content_run function uploading content $tmp_content_name to $test_content2} );

# Cleanup content:
unlink($tmp_content_name);
ok( $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'delete'} = \1;
$content_config->{'remote'} = \$test_content1;
ok( $sling->content_run($content_config), q{check content_run function deleting content $test_content1} );
$content_config->{'remote'} = \$test_content2;
ok( $sling->content_run($content_config), q{check content_run function deleting content $test_content2} );
$content_config->{'remote'} = \$test_content3;
ok( $sling->content_run($content_config), q{check content_run function deleting content $test_content3} );

ok( $content_config = $sling->content_config, 'check content_config function' );
$content_config->{'exists'} = \1;
$content_config->{'remote'} = \$test_content1;
ok( $sling->content_run($content_config), q{check content_run function exists test for $test_content1} );

ok( ! $content->check_exists( $test_content1 ),
    "Sling Test: Content \"$test_content1\" should no longer exist." );
ok( ! $content->check_exists( $test_content2 ),
    "Sling Test: Content \"$test_content2\" should no longer exist." );
ok( ! $content->check_exists( $test_content3 ),
    "Sling Test: Content \"$test_content3\" should no longer exist." );

################################################################################
# Testing Group:

# add group:
ok( my $group_config = $sling->group_config, 'check group_config function' );
$group_config->{'add'} = \$test_group1;
ok( $sling->group_run($group_config), q{check group_run function add for $test_group1} );

# Test group additions from file:
my ( $tmp_group_additions_handle, $tmp_group_additions_name ) = File::Temp::tempfile();
ok( $group_config = $sling->group_config, 'check group_config function' );
$group_config->{'additions'} = \$tmp_group_additions_name;
ok( $sling->group_run($group_config), q{check group_run function additions} );
unlink( $tmp_group_additions_name ); 

# view and check group exists:
ok( $group_config = $sling->group_config, 'check group_config function' );
$group_config->{'view'} = \$test_group1;
ok( $sling->group_run($group_config), q{check group_run function view for $test_group1} );

ok( $group_config = $sling->group_config, 'check group_config function' );
$group_config->{'exists'} = \$test_group1;
ok( $sling->group_run($group_config), q{check group_run function check exists for $test_group1} );

# add group member:
ok( my $group_member_config = $sling->group_member_config, 'check group_member_config function' );
$group_member_config->{'add'} = \$test_user;
$group_member_config->{'group'} = \$test_group1;
ok( $sling->group_member_run($group_member_config), q{check group_member_run function add for $test_group1} );

# Test group member additions from file:
my ( $tmp_group_member_additions_handle, $tmp_group_member_additions_name ) = File::Temp::tempfile();
ok( $group_member_config = $sling->group_member_config, 'check group_member_config function' );
$group_member_config->{'additions'} = \$tmp_group_member_additions_name;
ok( $sling->group_member_run($group_member_config), q{check group_member_run function additions} );
unlink( $tmp_group_member_additions_name ); 

ok( $group_member_config = $sling->group_member_config, 'check group_member_config function' );
$group_member_config->{'view'} = \1;
$group_member_config->{'group'} = \$test_group1;
ok( $sling->group_member_run($group_member_config), q{check group_member_run function view for $test_group1} );

ok( $group_member_config = $sling->group_member_config, 'check group_member_config function' );
$group_member_config->{'exists'} = \$test_user;
$group_member_config->{'group'} = \$test_group1;
ok( $sling->group_member_run($group_member_config), q{check group_member_run function check exists for $test_group1} );

ok( $group_member_config = $sling->group_member_config, 'check group_member_config function' );
$group_member_config->{'delete'} = \$test_user;
$group_member_config->{'group'} = \$test_group1;
ok( $sling->group_member_run($group_member_config), q{check group_member_run function delete for $test_group1} );

# Cleanup group:
ok( $group_config = $sling->group_config, 'check group_config function' );
$group_config->{'delete'} = \$test_group1;
ok( $sling->group_run($group_config), q{check group_run function delete for $test_group1} );

ok( ! $group->check_exists( $test_group1 ),
    "Sling Test: Content \"$test_group1\" should no longer exist." );

# Cleanup user:
ok( $user_config = $sling->user_config, 'check user_config function' );
$user_config->{'delete'} = \$test_user;
ok( $sling->user_run($user_config), q{check user_run function delete user $test_user} );
ok( ! $user->check_exists( $test_user ),
    "Sling Test: User \"$test_user\" should no longer exist." );
