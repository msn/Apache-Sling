#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 14;
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

ok( my $group_member_config = $sling->group_member_config, 'check group_member_config function' );
ok( my $json_query_servlet_config = $sling->json_query_servlet_config, 'check json_query_servlet_config function' );

ok( $sling->group_member_run($group_member_config), 'check group_member_run function' );
ok( $sling->json_query_servlet_run($json_query_servlet_config), 'check json_query_servlet_run function' );

throws_ok { $sling->group_member_run() } qr/No group_member config supplied!/, 'check group_member_run function croaks with no config supplied';
throws_ok { $sling->json_query_servlet_run() } qr/No json query servlet config supplied!/, 'check json_query_servlet_run function croaks with no config supplied';
