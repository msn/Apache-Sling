#!/usr/bin/perl -w

package Apache::Sling::Authn;

use 5.008001;
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

our $VERSION = '0.12';

#{{{sub new
sub new {
    my ( $class, $url, $username, $password, $type, $verbose, $log ) = @_;
    $url     = Apache::Sling::URL::url_input_sanitize($url);
    $type    = ( defined $type ? $type : 'basic' );
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
    $authn->login_user;
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

#{{{sub login_user
sub login_user {
    my ($authn) = @_;

    # Apply basic authentication to the user agent if url, username and
    # password are supplied:
    if (   defined $authn->{'BaseURL'}
        && defined $authn->{'Username'}
        && defined $authn->{'Password'} )
    {
        if ( $authn->{'Type'} eq 'basic' ) {
            my $success = $authn->basic_login();
            if ( !$success ) {
                if ( $authn->{'Verbose'} >= 1 ) {
                    Apache::Sling::Print::print_result($authn);
                }
                croak 'Basic Auth log in for user "'
                  . $authn->{'Username'}
                  . '" at URL "'
                  . $authn->{'BaseURL'}
                  . "\" was unsuccessful\n";
            }
        }
        else {
            croak 'Unsupported auth type: "' . $authn->{'Type'} . "\"\n";
        }
        if ( $authn->{'Verbose'} >= 1 ) {
            Apache::Sling::Print::print_result($authn);
        }
    }
    return 1;
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

Apache::Sling::Authn - Authenticate to an Apache Sling instance.

=head1 ABSTRACT

Useful utility functions for general Authn functionality.

=head1 USAGE

use Apache::Sling::Authn;

=head1 DESCRIPTION

Library providing useful utility functions for general Authn functionality.

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
