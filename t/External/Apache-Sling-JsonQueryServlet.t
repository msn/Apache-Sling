#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::JsonQueryServlet' ); }

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;

# Check error is thrown without auth:
throws_ok{ my $jsonqueryobject = Apache::Sling::JsonQueryServlet->new(); } qr%no authn provided!%, 'Check JSON query servlet creation croaks with authn missing';

# authn object:
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
# json query object:
my $jsonqueryobject = Apache::Sling::JsonQueryServlet->new( \$authn, $verbose, $log );
isa_ok $jsonqueryobject, 'Apache::Sling::JsonQueryServlet', 'jsonqueryservlet';

$jsonqueryobject = Apache::Sling::JsonQueryServlet->new( \$authn );
isa_ok $jsonqueryobject, 'Apache::Sling::JsonQueryServlet', 'jsonqueryservlet';

# Run tests:
ok( defined $jsonqueryobject,
    "User Test: Sling JSON Query Object successfully created." );

# all_nodes:
ok( $jsonqueryobject->all_nodes(),
    "JSON Query Servlet Test: querying all nodes completed successfully." );
