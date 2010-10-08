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
    my $help;
    my $log;
    my $man;
    my $number_forks = 1;
    my $password;
    my $url;
    my $user;
    my $verbose;

    my $sling = { MaxForks => $max_allowed_forks,
                  Help     => $help,
		  Log      => $log,
		  Man      => $man,
		  Pass     => $password,
		  Threads  => $number_forks,
		  URL      => $url,
		  User     => $user,
		  Verbose  => $verbose };
    bless $sling, $class;
    return $sling;
}

#}}}

#{{{sub check_forks

sub check_forks {
    my ( $sling ) = @_;
    $sling->{'Threads'} = ( $sling->{'Threads'} || 1 );
    $sling->{'Threads'} = ( $sling->{'Threads'} =~ /^[0-9]+$/xms ?
    $sling->{'Threads'} : 1 );
    $sling->{'Threads'} =
      ( $sling->{'Threads'} < $sling->{'MaxForks'} ? $sling->{'Threads'} : 1 );
    return 1;
}

#}}}

#{{{sub user_config

sub user_config {
    my ($sling) = @_;
    my $act_on_pass;
    my $additions;
    my $add_user;
    my $auth;
    my $change_pass_user;
    my $delete_user;
    my $exists_user;
    my $me_user;
    my $new_pass;
    my @properties;
    my $sites_user;
    my $update_user;
    my $view_user;

    my %user_config = (
        'help'            => \$sling->{'Help'},
        'log'             => \$sling->{'Log'},
        'man'             => \$sling->{'Man'},
        'pass'            => \$sling->{'Pass'},
        'threads'         => \$sling->{'Threads'},
        'url'             => \$sling->{'URL'},
        'user'            => \$sling->{'User'},
        'verbose'         => \$sling->{'Verbose'},
        'add'             => \$add_user,
        'additions'       => \$additions,
        'auth'            => \$auth,
        'change-password' => \$change_pass_user,
        'delete'          => \$delete_user,
        'exists'          => \$exists_user,
        'me'              => \$me_user,
        'new-password'    => \$new_pass,
        'password'        => \$act_on_pass,
        'property'        => \@properties,
        'sites'           => \$sites_user,
        'update'          => \$update_user,
        'view'            => \$view_user
    );

    return \%user_config;
}

#}}}

#{{{sub user_run
sub user_run {
    my ( $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No user config supplied!';
    }
    $sling->check_forks;

    if ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding users from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message",
            $sling->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $sling->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a separate authorization per fork:
                my $authn = new Apache::Sling::Authn(
                    $sling->{'URL'},
                    $sling->{'User'},
                    $sling->{'Pass'},
                    ${ $config->{'auth'} },
                    $sling->{'Verbose'},
                    $sling->{'Log'}
                );
                my $user = new Apache::Sling::User(
                    \$authn,
                    $sling->{'verbose'},
                    $sling->{'log'}
                );
                $user->add_from_file( { $config->{'additions'} },
                    $i, $sling->{'Threads'} );
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
                    $sling->{'URL'},
                    $sling->{'User'},
                    $sling->{'Pass'},
                    ${ $config->{'auth'} },
                    $sling->{'Verbose'},
                    $sling->{'Log'}
        );
        my $user = new Apache::Sling::User(
                    \$authn,
                    $sling->{'verbose'},
                    $sling->{'log'}
        );
        if ( defined ${ $config->{'exists'} } ) {
            $user->check_exists( ${ $config->{'exists'} } );
        }
        elsif ( defined ${ $config->{'me'} } ) {
            $user->me();
        }
        elsif ( defined ${ $config->{'sites'} } ) {
            $user->sites();
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $user->add(
                ${ $config->{'add'} },
                ${ $config->{'password'} },
                @{ $config->{'property'} }
            );
        }
        elsif ( defined ${ $config->{'update'} } ) {
            $user->update( ${ $config->{'update'} },
                @{ $config->{'property'} } );
        }
        elsif ( defined ${ $config->{'change-password'} } ) {
            $user->change_password(
                ${ $config->{'change-password'} },
                ${ $config->{'password'} },
                ${ $config->{'new-password'} },
                ${ $config->{'new-password'} }
            );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $user->del( ${ $config->{'delete'} } );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $user->view( ${ $config->{'view'} } );
        }
        Apache::Sling::Print::print_result($user);
    }
    return 1;
}

#}}}

1;
__END__

=head1 NAME

Apache::Sling - Perl library for interacting with the apache sling web framework

=head1 ABSTRACT

Top level Entry point to the Apache Sling libraries. Provides a layer of
abstraction for configuring and running the various Sling operations.

=head1 METHODS

=head2 new

Create, set up, and return a Sling object.

=head1 USAGE

use Apache::Sling;

=head1 DESCRIPTION

The Apache::Sling perl library is designed to provide a perl based interface on
to the Apache sling web framework. 

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

1 on success.

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
