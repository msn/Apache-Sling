#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 29;
use Test::Exception;
BEGIN { use_ok('Apache::Sling') };
# sling object:
my $sling = Apache::Sling->new(16);
isa_ok $sling, 'Apache::Sling', 'sling';
ok( $sling->{ 'MaxForks' } eq '16', 'Check MaxForks set' );
ok( $sling->check_forks, 'check check_forks function threads undefined' );
$sling->{'Threads'} = 0;
ok( $sling->check_forks, 'check check_forks function threads 0' );
$sling->{'Threads'} = 8;
ok( $sling->check_forks, 'check check_forks function threads normal' );
$sling->{'Threads'} = 'eight';
ok( $sling->check_forks, 'check check_forks function threads written' );
$sling->{'Threads'} = 17;
ok( $sling->check_forks, 'check check_forks function threads bigger than max' );
ok( my $authz_config = $sling->authz_config, 'check authz_config function' );
ok( my $content_config = $sling->content_config, 'check content_config function' );
ok( my $group_config = $sling->group_config, 'check group_config function' );
ok( my $group_member_config = $sling->group_member_config, 'check group_member_config function' );
ok( my $json_query_servlet_config = $sling->json_query_servlet_config, 'check json_query_servlet_config function' );
ok( my $ldap_synch_config = $sling->ldap_synch_config, 'check ldap_synch_config function' );
ok( my $user_config = $sling->user_config, 'check user_config function' );

ok( $sling->authz_run($authz_config), 'check authz_run function' );
ok( $sling->content_run($content_config), 'check content_run function' );
ok( $sling->group_run($group_config), 'check group_run function' );
ok( $sling->group_member_run($group_member_config), 'check group_member_run function' );
ok( $sling->json_query_servlet_run($json_query_servlet_config), 'check json_query_servlet_run function' );
ok( $sling->ldap_synch_run($ldap_synch_config), 'check ldap_synch_run function' );
ok( $sling->user_run($user_config), 'check user_run function' );

throws_ok { $sling->authz_run() } qr/No authz config supplied!/, 'check authz_run function croaks with no config supplied';
throws_ok { $sling->content_run() } qr/No content config supplied!/, 'check content_run function croaks with no config supplied';
throws_ok { $sling->group_run() } qr/No group config supplied!/, 'check group_run function croaks with no config supplied';
throws_ok { $sling->group_member_run() } qr/No group_member config supplied!/, 'check group_member_run function croaks with no config supplied';
throws_ok { $sling->json_query_servlet_run() } qr/No json query servlet config supplied!/, 'check json_query_servlet_run function croaks with no config supplied';
throws_ok { $sling->ldap_synch_run() } qr/No ldap_synch config supplied!/, 'check ldap_synch_run function croaks with no config supplied';
throws_ok { $sling->user_run() } qr/No user config supplied!/, 'check user_run function croaks with no config supplied';
