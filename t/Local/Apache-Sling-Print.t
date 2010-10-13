#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 5;
use File::Temp;
BEGIN { use_ok( 'Apache::Sling::Print' ); }

ok( Apache::Sling::Print::print_lock('Check print_lock function'), 'Check print_lock function' );
ok( Apache::Sling::Print::print_with_lock('Check print_with_lock function'), 'Check print_with_lock function' );
my ( $tmp_print_file_handle, $tmp_print_file_name ) = File::Temp::tempfile();
ok( Apache::Sling::Print::print_file_lock('Check print_file_lock function',$tmp_print_file_name), 'Check print_file_lock function' );
unlink($tmp_print_file_name);
ok( Apache::Sling::Print::date_time('Check date_time function'), 'Check date_time function' );
