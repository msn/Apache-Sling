#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok( 'Apache::Sling::UserUtil' ); }

my @properties = '';
ok( Apache::Sling::UserUtil::add_setup( 'http://localhost:8080', 'user', 'pass', \@properties) eq
  "post http://localhost:8080/system/userManager/user.create.html \$post_variables = [':name','user','pwd','pass','pwdConfirm','pass']", 'Check add_setup function' );
push @properties, 'a=b';
ok( Apache::Sling::UserUtil::add_setup( 'http://localhost:8080', 'user', 'pass', \@properties) eq
  "post http://localhost:8080/system/userManager/user.create.html \$post_variables = [':name','user','pwd','pass','pwdConfirm','pass','a','b']", 'Check add_setup function with properties' );
ok( Apache::Sling::UserUtil::change_password_setup( 'http://localhost:8080', 'user', 'pass1', 'pass2', 'pass2' ) eq
  "post http://localhost:8080/system/userManager/user/user.changePassword.html \$post_variables = ['oldPwd','pass1','newPwd','pass2','newPwdConfirm','pass2']", 'Check change_password_setup function' );
ok( Apache::Sling::UserUtil::delete_setup( 'http://localhost:8080', 'user' ) eq
  "post http://localhost:8080/system/userManager/user/user.delete.html \$post_variables = []", 'Check delete_setup function' );
ok( Apache::Sling::UserUtil::exists_setup( 'http://localhost:8080', 'user' ) eq
  "get http://localhost:8080/system/userManager/user/user.tidy.json", 'Check exists_setup function' );
ok( Apache::Sling::UserUtil::sites_setup( 'http://localhost:8080' ) eq
  "get http://localhost:8080/system/sling/membership", 'Check sites_setup function' );
ok( Apache::Sling::UserUtil::update_setup( 'http://localhost:8080','user',\@properties ) eq
  "post http://localhost:8080/system/userManager/user/user.update.html \$post_variables = ['a','b']", 'Check update_setup function' );
