#!/usr/bin/perl

package Apache::Sling::Authn;

use 5.008008;
use strict;
use warnings;
use Carp;
use File::Temp;
use LWP::UserAgent ();
use Apache::Sling::AuthnUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;
use Apache::Sling::URL;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.10';

#{{{sub new
sub new {
    my ( $class, $url, $username, $password, $type, $verbose, $log ) = @_;
    if ( !defined $url ) { croak 'url not defined!'; }
    $type    = ( defined $type    ? $type    : 'basic' );
    $verbose = ( defined $verbose ? $verbose : 0 );

    my $lwp_user_agent = LWP::UserAgent->new( keep_alive => 1 );
    push @{ $lwp_user_agent->requests_redirectable }, 'POST';
    my $tmp_cookie_file_name =
      File::Temp::tempnam( File::Temp::tempdir( CLEANUP => 1 ), 'authn' );
    $lwp_user_agent->cookie_jar( { file => $tmp_cookie_file_name } );

    my $response;
    my $authn = {
        BaseURL  => "$url",
        LWP      => \$lwp_user_agent,
        Type     => $type,
        Username => $username,
        Password => $password,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };

# Authn references itself to be compatibile with Apache::Sling::Request::request
    $authn->{'Authn'} = \$authn;
    bless $authn, $class;

    # Apply basic authentication to the user agent if url, username and
    # password are supplied:
    if ( defined $url && defined $username && defined $password ) {
        if ( $type eq 'basic' ) {
            my $success = $authn->basic_login();
            if ( !$success ) {
                if ( $verbose >= 1 ) {
                    Apache::Sling::Print::print_result($authn);
                }
                croak
"Basic Auth log in for user \"$username\" at URL \"$url\" was unsuccessful\n";
            }
        }
        elsif ( $type eq 'form' ) {
            my $success = $authn->form_login();
            if ( !$success ) {
                if ( $verbose >= 1 ) {
                    Apache::Sling::Print::print_result($authn);
                }
                croak
"Form log in for user \"$username\" at URL \"$url\" was unsuccessful\n";
            }
        }
        else {
            croak "Unsupported auth type: \"$type\"\n";
        }
        if ( $verbose >= 1 ) {
            Apache::Sling::Print::print_result($authn);
        }
    }
    return $authn;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $class, $message, $response ) = @_;
    $class->{'Message'}  = $message;
    $class->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub basic_login
sub basic_login {
    my ($authn) = @_;
    my $res =
      Apache::Sling::Request::request( \$authn,
        Apache::Sling::AuthnUtil::basic_login_setup( $authn->{'BaseURL'} ) );
    my $success = Apache::Sling::AuthnUtil::basic_login_eval($res);
    my $message = 'Basic auth log in ';
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $authn->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub form_login
sub form_login {
    my ($authn)  = @_;
    my $username = $authn->{'Username'};
    my $password = $authn->{'Password'};
    my $res      = Apache::Sling::Request::request(
        \$authn,
        Apache::Sling::AuthnUtil::form_login_setup(
            $authn->{'BaseURL'}, $username, $password
        )
    );
    my $success = Apache::Sling::AuthnUtil::form_login_eval($res);
    my $message = "Form log in as user \"$username\" ";
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $authn->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub form_logout
sub form_logout {
    my ($authn) = @_;
    my $res =
      Apache::Sling::Request::request( \$authn,
        Apache::Sling::AuthnUtil::form_logout_setup( $authn->{'BaseURL'} ) );
    my $success = Apache::Sling::AuthnUtil::form_logout_eval($res);
    my $message = 'Form log out ';
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $authn->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub switch_user
sub switch_user {
    my ( $authn, $new_username, $new_password, $type, $check_basic ) = @_;
    if ( !defined $new_username ) {
        croak 'New username to switch to not defined';
    }
    if ( !defined $new_password ) {
        croak 'New password to use in switch not defined';
    }
    if (   ( $authn->{'Username'} !~ /^$new_username$/msx )
        || ( $authn->{'Password'} !~ /^$new_password$/msx ) )
    {
        $authn->{'Username'} = $new_username;
        $authn->{'Password'} = $new_password;
        if ( $authn->{'Type'} eq 'form' ) {

            # If we were previously using form auth then we must log
            # out with form auth, even if we are switching to basic auth.
            my $success = $authn->form_logout();
            if ( !$success ) {
                croak 'Form Auth log out for user "'
                  . $authn->{'Username'}
                  . '" at URL "'
                  . $authn->{'BaseURL'}
                  . "\" was unsuccessful\n";
            }
        }
        if ( defined $type ) {
            $authn->{'Type'} = $type;
        }
        $check_basic = ( defined $check_basic ? $check_basic : 0 );
        if ( $authn->{'Type'} eq 'basic' ) {
            if ($check_basic) {
                my $success = $authn->basic_login();
                if ( !$success ) {
                    croak
                      "Basic Auth log in for user \"$new_username\" at URL \""
                      . $authn->{'BaseURL'}
                      . "\" was unsuccessful\n";
                }
            }
            else {
                $authn->{'Message'} = 'Fast User Switch completed!';
            }
        }
        elsif ( $authn->{'Type'} eq 'form' ) {
            my $success = $authn->form_login();
            if ( !$success ) {
                croak "Form Auth log in for user \"$new_username\" at URL \""
                  . $authn->{'BaseURL'}
                  . "\" was unsuccessful\n";
            }
        }
        else {
            croak "Unsupported auth type: \"$type\"\n";
        }
    }
    else {
        $authn->{'Message'} = 'User already active, no need to switch!';
    }
    if ( $authn->{'Verbose'} >= 1 ) {
        Apache::Sling::Print::print_result($authn);
    }
    return 1;
}

#}}}

1;

__END__

=head1 NAME

Authn

=head1 ABSTRACT

useful utility functions for general Authn functionality.

=head1 USAGE

use Apache::Sling::Authn;

=head1 DESCRIPTION

Utility library providing useful utility functions for general Authn functionality.

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

LWP::UserAgent

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2010 Daniel David Parry <perl@ddp.me.uk>
