#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

my $authn   = new Apache::Sling::Authn('http://localhost:8080',undef,undef,'basic','1','log.txt');
my $user = new Apache::Sling::User(\$authn,'1','log.txt');
ok( $user->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $user->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $user->{ 'Message' } eq '',                      'Check Message set' );
ok( $user->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $user->{ 'Authn' },                      'Check authn defined' );
ok( defined $user->{ 'Response' },                   'Check response defined' );

$user->set_results( 'Test Message', undef );
ok( $user->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $user->{ 'Response' },          'Check response no longer defined' );
