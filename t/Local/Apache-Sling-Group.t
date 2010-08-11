#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Group' ); }

my $authn = new Apache::Sling::Authn('http://localhost:8080',undef,undef,'basic','1','log.txt');
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
