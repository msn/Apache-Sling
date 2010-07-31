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

our $VERSION = '0.09';

#{{{sub string_to_request

sub string_to_request {
    my ( $string, $authn, $verbose, $log ) = @_;
    if ( !defined $string ) { croak 'No string defined to turn into request!'; }
    my $lwp = ${$authn}->{'LWP'};
    if ( !defined $lwp ) {
        croak 'No reference to an lwp user agent supplied!';
    }
    my ( $action, $target, @req_variables ) = split q{ }, $string;
    my $request;
    if ( $action eq 'post' ) {
        my $variables = join q{ }, @req_variables;
        my $post_variables;
        my $success = eval $variables;
        if ( !defined $success ) {
            croak "Error parsing post variables: \"$variables\"";
        }
        $request = POST( "$target", $post_variables );
    }
    if ( $action eq 'data' ) {

        # multi-part form upload
        my $variables = join q{ }, @req_variables;
        my $post_variables;
        my $success = eval $variables;
        if ( !defined $success ) {
            croak "Error parsing post variables: \"$variables\"";
        }
        $request =
          POST( "$target", $post_variables, 'Content_Type' => 'form-data' );
    }
    if ( $action eq 'fileupload' ) {

        # multi-part form upload with the file name and file specified
        my $filename  = shift @req_variables;
        my $file      = shift @req_variables;
        my $variables = join q{ }, @req_variables;
        my $post_variables;
        my $success = eval $variables;

        if ( !defined $success ) {
            croak "Error parsing post variables: \"$variables\"";
        }
        push @{$post_variables}, $filename => ["$file"];
        $request =
          POST( "$target", $post_variables, 'Content_Type' => 'form-data' );
    }
    if ( $action eq 'put' ) {
        $request = PUT "$target";
    }
    if ( $action eq 'delete' ) {
        $request = DELETE "$target";
    }
    if ( !defined $request ) {
        $request = GET "$target";
    }
    if ( ${$authn}->{'Type'} eq 'basic' ) {
        my $username = ${$authn}->{'Username'};
        my $password = ${$authn}->{'Password'};
        if ( defined $username && defined $password ) {

            # Always add an Authorization header to deal with application not
            # properly requesting authentication to be sent:
            my $encoded = 'Basic ' . encode_base64("$username:$password");
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

sub request {
    my ( $object, $string ) = @_;
    if ( !defined $string ) { croak 'No string defined to turn into request!'; }
    if ( !defined $object ) {
        croak 'No reference to a suitable object supplied!';
    }
    my $authn = ${$object}->{'Authn'};
    if ( !defined $authn ) {
        croak 'Object does not reference a suitable auth object';
    }
    my $verbose = ${$object}->{'Verbose'};
    my $log     = ${$object}->{'Log'};
    my $lwp     = ${$authn}->{'LWP'};
    my $res =
      ${$lwp}->request( string_to_request( $string, $authn, $verbose, $log ) );
    return \$res;
}

#}}}

1;

__END__

=head1 NAME

Request

=head1 ABSTRACT

useful utility functions for general Request functionality.

=head1 METHODS

=head2 string_to_request

Function taking a string and converting to a GET or POST HTTP request.

=head2 request

Function to actually issue an HTTP request given a suitable string
representation of the request and an object which references a suitable LWP
object.

=head1 USAGE

use Apache::Sling::Request;

=head1 DESCRIPTION

Utility library providing useful utility functions for general Request functionality.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2010 Daniel David Parry <perl@ddp.me.uk>
