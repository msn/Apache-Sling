#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Request' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }

my $sling = Apache::Sling->new();
my $authn = new Apache::Sling::Authn(\$sling);
my $content = new Apache::Sling::Content(\$authn,'1','log.txt');
throws_ok { Apache::Sling::Request::string_to_request('',\$authn) } qr/Error generating request for blank target!/, 'Checking string_to_request function blank string';
throws_ok { Apache::Sling::Request::request(\$content,'') } qr/Error generating request for blank target!/, 'Checking request function blank string';
throws_ok { Apache::Sling::Request::request() } qr/No reference to a suitable object supplied!/, 'Check request function croaks without object';
throws_ok { Apache::Sling::Request::request(\$content) } qr/No string defined to turn into request!/, 'Check request function croaks without string';
