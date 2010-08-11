#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok( 'Apache::Sling::Authn' ); }

my $authn = new Apache::Sling::Authn('http://localhost:8080',undef,undef,'basic','1','log.txt');
ok( $authn->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $authn->{ 'Type' }    eq 'basic',                 'Check Auth type set' );
ok( $authn->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $authn->{ 'Message' } eq '',                      'Check Message set' );
ok( $authn->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( ! defined $authn->{ 'Username' },                 'Check user name not defined' );
ok( ! defined $authn->{ 'Password' },                 'Check password not defined' );
ok( defined $authn->{ 'Response' },                   'Check response defined' );

$authn->set_results( 'Test Message', undef );
ok( $authn->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $authn->{ 'Response' },        'Check response no longer defined' );
