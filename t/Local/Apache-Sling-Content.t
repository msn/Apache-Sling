#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

my $authn   = new Apache::Sling::Authn('http://localhost:8080',undef,undef,'basic','1','log.txt');
my $content = new Apache::Sling::Content(\$authn,'1','log.txt');
ok( $content->{ 'BaseURL' } eq 'http://localhost:8080', 'Check BaseURL set' );
ok( $content->{ 'Log' }     eq 'log.txt',               'Check Log set' );
ok( $content->{ 'Message' } eq '',                      'Check Message set' );
ok( $content->{ 'Verbose' } == 1,                       'Check Verbosity set' );
ok( defined $content->{ 'Authn' },                      'Check authn defined' );
ok( defined $content->{ 'Response' },                   'Check response defined' );

$content->set_results( 'Test Message', undef );
ok( $content->{ 'Message' } eq 'Test Message', 'Message now set' );
ok( ! defined $content->{ 'Response' },          'Check response no longer defined' );
