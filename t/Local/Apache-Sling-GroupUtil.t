#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok( 'Apache::Sling::GroupUtil' ); }

my @properties = '';
ok( Apache::Sling::GroupUtil::add_setup( 'http://localhost:8080', 'group', \@properties) eq
  "post http://localhost:8080/system/userManager/group.create.html \$post_variables = [':name','group']", 'Check add_setup function' );
push @properties, "a=b";
ok( Apache::Sling::GroupUtil::add_setup( 'http://localhost:8080', 'group', \@properties) eq
  "post http://localhost:8080/system/userManager/group.create.html \$post_variables = [':name','group','a','b']", 'Check add_setup function with variables' );
ok(Apache::Sling::GroupUtil::delete_setup('http://localhost:8080','group') eq
  "post http://localhost:8080/system/userManager/group/group.delete.html \$post_variables = []", 'Check delete_setup function' );
ok(Apache::Sling::GroupUtil::exists_setup('http://localhost:8080','group') eq
  "get http://localhost:8080/system/userManager/group/group.json", 'Check exists_setup function' );
ok(Apache::Sling::GroupUtil::member_add_setup('http://localhost:8080','group','user') eq
  "post http://localhost:8080/system/userManager/group/group.update.html \$post_variables = [':member','/system/userManager/user/user']",'Check member_add_setup function' );
ok(Apache::Sling::GroupUtil::member_delete_setup('http://localhost:8080','group','user') eq
  "post http://localhost:8080/system/userManager/group/group.update.html \$post_variables = [':member\@Delete','/system/userManager/user/user']",'Check member_delete_setup function' );
ok(Apache::Sling::GroupUtil::view_setup('http://localhost:8080','group') eq
  "get http://localhost:8080/system/userManager/group/group.tidy.json",'Check view_setup function' );
