#!/usr/bin/perl

package Apache::Sling::User;

use 5.008008;
use strict;
use warnings;
use Carp;
use Text::CSV;
use Apache::Sling::Print;
use Apache::Sling::Request;
use Apache::Sling::UserUtil;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.08';

=head1 NAME

User - user related functionality for Sling implemented over rest
APIs.

=head1 ABSTRACT

Perl library providing a layer of abstraction to the REST user methods

=cut

#{{{sub new

=pod

=head2 new

Create, set up, and return a User Agent.

=cut

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $user = {
        BaseURL  => $$authn->{'BaseURL'},
        Authn    => $authn,
        Message  => "",
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless( $user, $class );
    return $user;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $user, $message, $response ) = @_;
    $user->{'Message'}  = $message;
    $user->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $user, $actOnUser, $actOnPass, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::add_setup(
            $user->{'BaseURL'}, $actOnUser, $actOnPass, $properties
        )
    );
    my $success = Apache::Sling::UserUtil::add_eval($res);
    my $message = "User: \"$actOnUser\" ";
    $message .= ( $success ? "added!" : "was not added!" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub add_from_file
sub add_from_file {
    my ( $user, $file, $forkId, $numberForks ) = @_;
    my $csv           = Text::CSV->new();
    my $count         = 0;
    my $numberColumns = 0;
    my @column_headings;
    if ( open my ($input), "<", $file ) {
        while (<$input>) {
            if ( $count++ == 0 ) {

                # Parse file column headings first to determine field names:
                if ( $csv->parse($_) ) {
                    @column_headings = $csv->fields();

                    # First field must be site:
                    if ( $column_headings[0] !~ /^[Uu][Ss][Ee][Rr]$/x ) {
                        croak
"First CSV column must be the user ID, column heading must be \"user\". Found: \""
                          . $column_headings[0] . "\".\n";
                    }
                    if ( $column_headings[1] !~
                        /^[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]$/x )
                    {
                        croak
"Second CSV column must be the user password, column heading must be \"password\". Found: \""
                          . $column_headings[0] . "\".\n";
                    }
                    $numberColumns = @column_headings;
                }
                else {
                    croak "CSV broken, failed to parse line: "
                      . $csv->error_input;
                }
            }
            elsif ( $forkId == ( $count++ % $numberForks ) ) {
                my @properties;
                if ( $csv->parse($_) ) {
                    my @columns      = $csv->fields();
                    my $columns_size = @columns;

           # Check row has same number of columns as there were column headings:
                    if ( $columns_size != $numberColumns ) {
                        croak
"Found \"$columns_size\" columns. There should have been \"$numberColumns\".\nRow contents was: $_";
                    }
                    my $id       = $columns[0];
                    my $password = $columns[1];
                    for ( my $i = 2 ; $i < $numberColumns ; $i++ ) {
                        my $value = $column_headings[$i] . "=" . $columns[$i];
                        push( @properties, $value );
                    }
                    $user->add( $id, $password, \@properties );
                    Apache::Sling::Print::print_result($user);
                }
                else {
                    croak "CSV broken, failed to parse line: "
                      . $csv->error_input;
                }
            }
        }
        close($input);
    }
    return 1;
}

#}}}

#{{{sub change_password
sub change_password {
    my ( $user, $actOnUser, $actOnPass, $newPass, $newPassConfirm ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::change_password_setup(
            $user->{'BaseURL'}, $actOnUser, $actOnPass,
            $newPass,           $newPassConfirm
        )
    );
    my $success = Apache::Sling::UserUtil::change_password_eval($res);
    my $message = "User: \"$actOnUser\" ";
    $message .= ( $success ? "password changed!" : "password not changed!" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub del
sub del {
    my ( $user, $actOnUser ) = @_;
    my $res = Apache::Sling::Request::request( \$user,
        Apache::Sling::UserUtil::delete_setup( $user->{'BaseURL'}, $actOnUser )
    );
    my $success = Apache::Sling::UserUtil::delete_eval($res);
    my $message = "User: \"$actOnUser\" ";
    $message .= ( $success ? "deleted!" : "was not deleted!" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $user, $actOnUser ) = @_;
    my $res = Apache::Sling::Request::request( \$user,
        Apache::Sling::UserUtil::exists_setup( $user->{'BaseURL'}, $actOnUser )
    );
    my $success = Apache::Sling::UserUtil::exists_eval($res);
    my $message = "User \"$actOnUser\" ";
    $message .= ( $success ? "exists!" : "does not exist!" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub me
sub me {
    my ($user) = @_;
    my $res =
      Apache::Sling::Request::request( \$user,
        Apache::Sling::UserUtil::me_setup( $user->{'BaseURL'} ) );
    my $success = Apache::Sling::UserUtil::me_eval($res);
    my $message =
      (   $success
        ? $$res->content
        : "Problem fetching details for current user" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub sites
sub sites {
    my ($user) = @_;
    my $res =
      Apache::Sling::Request::request( \$user,
        Apache::Sling::UserUtil::sites_setup( $user->{'BaseURL'} ) );
    my $success = Apache::Sling::UserUtil::sites_eval($res);
    my $message =
      (   $success
        ? $$res->content
        : "Problem fetching details for current user" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub update
sub update {
    my ( $user, $actOnUser, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Apache::Sling::UserUtil::update_setup(
            $user->{'BaseURL'}, $actOnUser, $properties
        )
    );
    my $success = Apache::Sling::UserUtil::update_eval($res);
    my $message = "User: \"$actOnUser\" ";
    $message .= ( $success ? "updated!" : "was not updated!" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub view
sub view {
    my ( $user, $actOnUser ) = @_;
    my $res = Apache::Sling::Request::request( \$user,
        Apache::Sling::UserUtil::exists_setup( $user->{'BaseURL'}, $actOnUser )
    );
    my $success = Apache::Sling::UserUtil::exists_eval($res);
    my $message =
      ( $success ? $$res->content : "Problem viewing user: \"$actOnUser\"" );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

=head1 ABSTRACT

=head1 METHODS

=head1 USAGE

=head1 DESCRIPTION

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

COPYRIGHT: Daniel David Parry <perl@ddp.me.uk>
