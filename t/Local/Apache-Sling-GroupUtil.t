#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling::GroupUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

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
my $res = HTTP::Response->new( '200' );
ok( Apache::Sling::GroupUtil::add_eval( \$res ), 'Check add_eval function' );
ok( Apache::Sling::GroupUtil::delete_eval( \$res ), 'Check delete_eval function' );
ok( Apache::Sling::GroupUtil::exists_eval( \$res ), 'Check exists_eval function' );
ok( Apache::Sling::GroupUtil::member_add_eval( \$res ), 'Check member_add_eval function' );
ok( ! Apache::Sling::GroupUtil::member_delete_eval( \$res ), 'Check member_delete_eval function no content' );
ok( ! Apache::Sling::GroupUtil::view_eval( \$res ), 'Check view_eval function no content' );
$res->content("OK");
ok( Apache::Sling::GroupUtil::member_delete_eval( \$res ), 'Check member_delete_eval function' );
ok( Apache::Sling::GroupUtil::view_eval( \$res ), 'Check view_eval function' );
throws_ok { Apache::Sling::GroupUtil::add_setup() } qr/No base url defined to add against!/, 'Check add_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupUtil::delete_setup() } qr/No base url defined to delete against!/, 'Check delte_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupUtil::exists_setup() } qr/No base url to check existence against!/, 'Check exists_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupUtil::member_add_setup() } qr/No base url defined to add against!/, 'Check member_add_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupUtil::member_add_setup('http://localhost:8080','group') } qr/No member name defined to add!/, 'Check member_add_setup function croaks without add_member specified';
throws_ok { Apache::Sling::GroupUtil::member_delete_setup() } qr/No base url defined to delete against!/, 'Check member_delete_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupUtil::member_delete_setup('http://localhost:8080') } qr/No group name defined to delete member from!/, 'Check member_delete_setup function croaks without group specified';
throws_ok { Apache::Sling::GroupUtil::member_delete_setup('http://localhost:8080','group') } qr/No member name defined to delete!/, 'Check member_delete_setup function croaks without member specified';
throws_ok { Apache::Sling::GroupUtil::view_setup() } qr/No base url to view with defined!/, 'Check view_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupUtil::view_setup() } qr/No base url to view with defined!/, 'Check view_setup function croaks without base_url specified';
