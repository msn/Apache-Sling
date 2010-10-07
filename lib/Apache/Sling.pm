#!/usr/bin/perl -w
package Apache::Sling;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::Authn;
use Apache::Sling::User;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.12';

#{{{sub new

sub new {
    my ( $class, $max_allowed_forks ) = @_;

    # control the maximum number of forks that can be
    # created when testing concurrency:
    $max_allowed_forks =
      ( defined $max_allowed_forks ? $max_allowed_forks : 32 );
    my $sling = { MaxForks => $max_allowed_forks };
    bless $sling, $class;
    return $sling;
}

#}}}

#{{{sub check_forks

sub check_forks {
    my ( $sling, $number_forks ) = @_;
    $number_forks = ( $number_forks || 1 );
    $number_forks = ( $number_forks =~ /^[0-9]+$/xms ? $number_forks : 1 );
    $number_forks =
      ( $number_forks < $sling->{'MaxForks'} ? $number_forks : 1 );
    return $number_forks;
}

#}}}

#{{{sub user_options

sub user_options {
    my ($sling) = @_;
    my $act_on_pass;
    my $additions;
    my $add_user;
    my $auth;
    my $change_pass_user;
    my $delete_user;
    my $exists_user;
    my $help;
    my $log;
    my $man;
    my $me_user;
    my $new_pass;
    my $number_forks = 1;
    my $password;
    my @properties;
    my $sites_user;
    my $update_user;
    my $url;
    my $username;
    my $verbose;
    my $view_user;

    my %options = (
        'add'             => \$add_user,
        'additions'       => \$additions,
        'auth'            => \$auth,
        'change-password' => \$change_pass_user,
        'delete'          => \$delete_user,
        'exists'          => \$exists_user,
        'help'            => \$help,
        'log'             => \$log,
        'man'             => \$man,
        'me'              => \$me_user,
        'new-password'    => \$new_pass,
        'password'        => \$act_on_pass,
        'pass'            => \$password,
        'property'        => \@properties,
        'sites'           => \$sites_user,
        'threads'         => \$number_forks,
        'update'          => \$update_user,
        'url'             => \$url,
        'user'            => \$username,
        'verbose'         => \$verbose,
        'view'            => \$view_user
    );

    return \%options;
}

#}}}

#{{{sub user_run
sub user_run {
    my ( $sling, $options ) = @_;
    if ( !defined $options ) {
        croak 'No user options supplied!';
    }
    ${ $options->{'threads'} } =
      $sling->check_forks( ${ $options->{'threads'} } );

    if ( defined ${ $options->{'additions'} } ) {
        my $message =
          "Adding users from file \"" . ${ $options->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message",
            ${ $options->{'log'} } );
        my @childs = ();
        for my $i ( 0 .. ${ $options->{'threads'} } ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a separate authorization per fork:
                my $authn = new Apache::Sling::Authn(
                    ${ $options->{'url'} },
                    ${ $options->{'user'} },
                    ${ $options->{'pass'} },
                    ${ $options->{'auth'} },
                    ${ $options->{'verbose'} },
                    ${ $options->{'log'} }
                );
                my $user = new Apache::Sling::User(
                    \$authn,
                    ${ $options->{'verbose'} },
                    ${ $options->{'log'} }
                );
                $user->add_from_file( { $options->{'additions'} },
                    $i, ${ $options->{'threads'} } );
                exit 0;
            }
            else {
                croak "Could not fork $i!";
            }
        }
        foreach (@childs) { waitpid $_, 0; }
    }
    else {
        my $authn = new Apache::Sling::Authn(
            ${ $options->{'url'} },
            ${ $options->{'user'} },
            ${ $options->{'pass'} },
            ${ $options->{'auth'} },
            ${ $options->{'verbose'} },
            ${ $options->{'log'} }
        );
        my $user = new Apache::Sling::User(
            \$authn,
            ${ $options->{'verbose'} },
            ${ $options->{'log'} }
        );
        if ( defined ${ $options->{'exists'} } ) {
            $user->check_exists( ${ $options->{'exists'} } );
        }
        elsif ( defined ${ $options->{'me'} } ) {
            $user->me();
        }
        elsif ( defined ${ $options->{'sites'} } ) {
            $user->sites();
        }
        elsif ( defined ${ $options->{'add'} } ) {
            $user->add(
                ${ $options->{'add'} },
                ${ $options->{'password'} },
                @{ $options->{'property'} }
            );
        }
        elsif ( defined ${ $options->{'update'} } ) {
            $user->update( ${ $options->{'update'} },
                @{ $options->{'property'} } );
        }
        elsif ( defined ${ $options->{'change-password'} } ) {
            $user->change_password(
                ${ $options->{'change-password'} },
                ${ $options->{'password'} },
                ${ $options->{'new-password'} },
                ${ $options->{'new-password'} }
            );
        }
        elsif ( defined ${ $options->{'delete'} } ) {
            $user->del( ${ $options->{'delete'} } );
        }
        elsif ( defined ${ $options->{'view'} } ) {
            $user->view( ${ $options->{'view'} } );
        }
        Apache::Sling::Print::print_result($user);
        return 1;
    }
}

#}}}

1;
__END__

=head1 NAME

Apache::Sling - Perl library for interacting with the apache sling web framework

=head1 SYNOPSIS

  use Apache::Sling;

=head1 DESCRIPTION

The Apache::Sling perl library is designed to provide a perl based interface on
to the Apache sling web framework. 

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://sling.apache.org

=head1 AUTHOR

D. D. Parry, E<lt>perl@ddp.me.ukE<gt>

=head1 VERSION

0.12

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: Daniel David Parry <perl@ddp.me.uk>
