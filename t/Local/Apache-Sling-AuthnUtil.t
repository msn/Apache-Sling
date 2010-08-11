#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok( 'Apache::Sling::AuthnUtil' ); }

ok( Apache::Sling::AuthnUtil::basic_login_setup( 'http://localhost:8080' ) eq
  'get http://localhost:8080/system/sling/login?sling:authRequestLogin=1', 'Check basic_login_setup function' );
