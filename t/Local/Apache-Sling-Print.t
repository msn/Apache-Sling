#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok( 'Apache::Sling::Print' ); }

ok( Apache::Sling::Print::print_lock('Check print_lock function'), 'Check print_lock function' );
ok( Apache::Sling::Print::print_with_lock('Check print_with_lock function'), 'Check print_with_lock function' );
