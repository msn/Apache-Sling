#!/usr/bin/perl

package Apache::Sling::Request;

use 5.008008;
use strict;
use warnings;
use Carp;
use HTTP::Request::Common qw(DELETE GET POST PUT);
use MIME::Base64;
use Apache::Sling::Print;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.05';

=head1 NAME

Request - useful utility functions for general Request functionality.

=head1 ABSTRACT

Utility library providing useful utility functions for general Request functionality.

=cut

#{{{sub string_to_request

=pod

=head2 string_to_request

Function taking a string and converting to a GET or POST HTTP request.

=cut

sub string_to_request {
    my ( $string, $authn, $verbose, $log ) = @_;
    croak "No string defined to turn into request!" unless defined $string;
    my $lwp = $$authn->{'LWP'};
    croak "No reference to an lwp user agent supplied!" unless defined $lwp;
    my ( $action, $target, @reqVariables ) = split( ' ', $string );
    my $request;
    if ( $action =~ /^post$/x ) {
        my $variables = join( " ", @reqVariables );
        my $postVariables;
        my $success = eval ( $variables );
        if ( !defined $success ) {
            croak "Error \"$@\" parsing post variables: \"$variables\"";
        }
        $request = POST( "$target", $postVariables );
    }
    if ( $action =~ /^data$/x ) {

        # multi-part form upload
        my $variables = join( " ", @reqVariables );
        my $postVariables;
        my $success = eval ( $variables );
        if ( !defined $success ) {
            croak "Error \"$@\" parsing post variables: \"$variables\"";
        }
        $request =
          POST( "$target", $postVariables, 'Content_Type' => 'form-data' );
    }
    if ( $action =~ /^fileupload$/x ) {

        # multi-part form upload with the file name and file specified
        my $filename  = shift(@reqVariables);
        my $file      = shift(@reqVariables);
        my $variables = join( " ", @reqVariables );
        my $postVariables;
        my $success = eval ( $variables );

        if ( !defined $success ) {
            croak "Error \"$@\" parsing post variables: \"$variables\"";
        }
        push( @{$postVariables}, $filename => ["$file"] );
        $request =
          POST( "$target", $postVariables, 'Content_Type' => 'form-data' );
    }
    if ( $action =~ /^put$/x ) {
        $request = PUT "$target";
    }
    if ( $action =~ /^delete$/x ) {
        $request = DELETE "$target";
    }
    if ( ! defined $request ) {
        $request = GET "$target";
    }
    if ( $$authn->{'Type'} =~ /^basic$/x ) {
        my $username = $$authn->{'Username'};
        my $password = $$authn->{'Password'};
        if ( defined $username && defined $password ) {

            # Always add an Authorization header to deal with application not
            # properly requesting authentication to be sent:
            my $encoded = "Basic " . encode_base64("$username:$password");
            $request->header( 'Authorization' => $encoded );
        }
    }
    if ( $verbose >= 2 ) {
        Apache::Sling::Print::print_with_lock(
            "**** String representation of compiled request:\n"
              . $request->as_string,
            $log
        );
    }
    return $request;
}

#}}}

#{{{sub request

=pod

=head2 request

Function to actually issue an HTTP request given a suitable string
representation of the request and an object which references a suitable LWP
object.

=cut

sub request {
    my ( $object, $string ) = @_;
    croak "No string defined to turn into request!"     unless defined $string;
    croak "No reference to a suitable object supplied!" unless defined $object;
    my $authn = $$object->{'Authn'};
    croak "Object does not reference a suitable auth object"
      unless defined $authn;
    my $verbose = $$object->{'Verbose'};
    my $log     = $$object->{'Log'};
    my $lwp     = $$authn->{'LWP'};
    my $res =
      $$lwp->request( string_to_request( $string, $authn, $verbose, $log ) );
    return \$res;
}

#}}}

1;
