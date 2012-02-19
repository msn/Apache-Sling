#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Group' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';

my $authn = new Apache::Sling::Authn(\$sling);
throws_ok { my $group = new Apache::Sling::Group() } qr/no authn provided!/, 'Check creating group croaks without authn provided';
my $group = new Apache::Sling::Group(\$authn,'1','log.txt');

ok( $group->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $group->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $group->{ 'Message' } eq '',                      'Check Message set' );
ok( $group->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $group->{ 'Authn' },                      'Check authn defined' );
ok( defined $group->{ 'Response' },                   'Check response defined' );

$group->set_results( 'Test Message', undef );
ok( $group->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $group->{ 'Response' },        'Check response no longer defined' );
throws_ok { $group->add() } qr/No group name defined to add!/, 'Check add function croaks without group specified';
throws_ok { $group->del() } qr/No group name defined to delete!/, 'Check del function croaks without group specified';
throws_ok { $group->check_exists() } qr/No group to check existence of defined!/, 'Check check_exists function croaks without group specified';
throws_ok { $group->member_add() } qr/No group name defined to add to!/, 'Check member_add function croaks without group specified';
throws_ok { $group->member_delete() } qr/No group name defined to delete from!/, 'Check member_delete function croaks without group specified';
throws_ok { $group->member_exists() } qr/No group to view defined!/, 'Check member_exists function croaks without group specified';
throws_ok { $group->member_view() } qr/No group to view defined!/, 'Check member_view function croaks without group specified';
throws_ok { $group->view() } qr/No group to view defined!/, 'Check view function croaks without group specified';

my $file = "\n";
throws_ok { $group->add_from_file() } qr/File to upload from not defined/, 'Check add_from_file function croaks without file';
throws_ok { $group->add_from_file(\$file) } qr/First CSV column must be the group ID, column heading must be "group". Found: ""./, 'Check add_from_file function croaks with blank file';
throws_ok { $group->add_from_file('/tmp/__non__--__tnetsixe__') } qr{Problem opening file: '/tmp/__non__--__tnetsixe__'}, 'Check add_from_file function croaks with non-existent file specified';

throws_ok { $group->member_add_from_file() } qr/File to upload from not defined/, 'Check member_add_from_file function croaks without file';
throws_ok { $group->member_add_from_file(\$file) } qr/First CSV column must be the group ID, column heading must be "group". Found: ""./, 'Check member_add_from_file function croaks with blank file';
throws_ok { $group->member_add_from_file('/tmp/__non__--__tnetsixe__') } qr{Problem opening file: '/tmp/__non__--__tnetsixe__'}, 'Check member_add_from_file function croaks with non-existent file specified';
