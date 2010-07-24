#!/usr/bin/perl

package Apache::Sling::AuthnUtil;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.07';

#{{{sub basic_login_setup
sub basic_login_setup {
    my ($base_url) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    return "get $base_url/system/sling/login?sling:authRequestLogin=1";
}

#}}}

#{{{sub basic_login_eval
sub basic_login_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub form_login_setup
sub form_login_setup {
    my ( $base_url, $username, $password ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    if ( !defined $username ) {
        croak 'No username supplied to attempt logging in with!';
    }
    if ( !defined $password ) {
        croak
"No password supplied to attempt logging in with for user name: $username!";
    }
    my $post_variables =
"\$postVariables = ['sakaiauth:un','$username','sakaiauth:pw','$password','sakaiauth:login','1']";
    return "post $base_url/system/sling/formlogin $post_variables";
}

#}}}

#{{{sub form_login_eval
sub form_login_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub form_logout_setup
sub form_logout_setup {
    my ($base_url) = @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    my $post_variables = q{$postVariables = ['sakaiauth:logout','1']};
    return "post $base_url/system/sling/formlogin $post_variables";
}

#}}}

#{{{sub form_logout_eval
sub form_logout_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

1;

__END__

=head1 NAME

AuthnUtil - useful utility functions for general Authn functionality.

=head1 ABSTRACT

Utility library providing useful utility functions for general Authn functionality.

=head1 METHODS

=head2 basic_login_setup

Returns a textual representation of the request needed to log the user in to
the system via a basic auth based login.

=head2 basic_login_eval

Verify whether the log in attempt for the user to the system was successful.

=head2 form_login_setup

Returns a textual representation of the request needed to log the user in to
the system via a form based login.

=head2 form_login_eval

Verify whether the log in attempt for the user to the system was successful.

=head2 form_logout_setup

Returns a textual representation of the request needed to log the user out of
the system via a form based mechanism.

=head2 form_logout_eval

Verify whether the log out attempt for the user from the system was successful.

=head1 USAGE

=head1 DESCRIPTION

=head1 REQUIRED ARGUMENTS

=head1 OPTIONS

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

