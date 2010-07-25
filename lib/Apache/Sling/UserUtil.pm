#!/usr/bin/perl

package Apache::Sling::UserUtil;

use 5.008008;
use strict;
use warnings;
use Carp;
use Apache::Sling::URL;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.08';

=head1 NAME

UserUtil - Utility library returning strings representing Rest queries that
perform user related actions in the system.

=head1 ABSTRACT

UserUtil perl library essentially provides the request strings needed to
interact with user functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=cut

#{{{sub add_setup

=pod

=head2 add_setup

Returns a textual representation of the request needed to add the user to the
system.

=cut

sub add_setup {
    my ( $base_url, $actOnUser, $actOnPass, $properties ) = @_;
    if ( !defined $base_url )   { croak 'No base url defined to add against!'; }
    if ( !defined $actOnUser ) { croak 'No user name defined to add!'; }
    if ( !defined $actOnPass ) {
        croak "No user password defined to add for user $actOnUser!";
    }
    my $property_post_vars =
      Apache::Sling::URL::properties_array_to_string($properties);
    my $post_variables =
"\$post_variables = [':name','$actOnUser','pwd','$actOnPass','pwdConfirm','$actOnPass'";
    if ( defined $property_post_vars && $property_post_vars ne q{} ) {
        $post_variables .= ",$property_post_vars";
    }
    $post_variables .= "]";
    return "post $base_url/system/userManager/user.create.html $post_variables";
}

#}}}

#{{{sub add_eval

=pod

=head2 add_eval

Check result of adding user to the system.

=cut

sub add_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub change_password_setup

=pod

=head2 change_password_setup

Returns a textual representation of the request needed to change the password
of the user in the system.

=cut

sub change_password_setup {
    my ( $base_url, $actOnUser, $actOnPass, $newPass, $newPassConfirm ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $actOnUser ) {
        croak 'No user name defined to change password for!';
    }
    if ( !defined $actOnPass ) {
        croak "No current password defined for $actOnUser!";
    }
    if ( !defined $newPass ) {
        croak "No new password defined for $actOnUser!";
    }
    if ( !defined $newPassConfirm ) {
        croak "No confirmation of new password defined for $actOnUser!";
    }
    my $post_variables =
"\$post_variables = ['oldPwd','$actOnPass','newPwd','$newPass','newPwdConfirm','$newPassConfirm']";
    return
"post $base_url/system/userManager/user/$actOnUser.changePassword.html $post_variables";
}

#}}}

#{{{sub change_password_eval

=pod

=head2 change_password_eval

Verify whether the change password attempt for the user in the system was successful.

=cut

sub change_password_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub delete_setup

=pod

=head2 delete_setup

Returns a textual representation of the request needed to delete the user from
the system.

=cut

sub delete_setup {
    my ( $base_url, $actOnUser ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to delete against!'; }
    if ( !defined $actOnUser ) { croak 'No user name defined to delete!'; }
    my $post_variables = "\$post_variables = []";
    return
"post $base_url/system/userManager/user/$actOnUser.delete.html $post_variables";
}

#}}}

#{{{sub delete_eval

=pod

=head2 delete_eval

Check result of deleting user from the system.

=cut

sub delete_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub exists_setup

=pod

=head2 exists_setup

Returns a textual representation of the request needed to test whether a given
username exists in the system.

=cut

sub exists_setup {
    my ( $base_url, $actOnUser ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to check existence against!';
    }
    if ( !defined $actOnUser ) {
        croak 'No user to check existence of defined!';
    }
    return "get $base_url/system/userManager/user/$actOnUser.tidy.json";
}

#}}}

#{{{sub exists_eval

=pod

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the username does exist in the system,
else false.

=cut

sub exists_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub me_setup

=pod

=head2 me_setup

Returns a textual representation of the request needed to return information
about the current user.

=cut

sub me_setup {
    my ($base_url) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to check existence against!';
    }
    return "get $base_url/system/me";
}

#}}}

#{{{sub me_eval

=pod

=head2 me_eval

Inspects the result returned from issuing the request generated in me_setup
returning true if the result indicates information was returned successfully,
else false.

=cut

sub me_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub sites_setup

=pod

=head2 sites_setup

Returns a textual representation of the request needed to return the list of
sites the current user is a member of.

=cut

sub sites_setup {
    my ($base_url) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to check membership of sites against!';
    }
    return "get $base_url/system/sling/membership";
}

#}}}

#{{{sub sites_eval

=pod

=head2 sites_eval

Inspects the result returned from issuing the request generated in sites_setup
returning true if the result indicates information was returned successfully,
else false.

=cut

sub sites_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub update_setup

=pod

=head2 update_setup

Returns a textual representation of the request needed to update the user in the
system.

=cut

sub update_setup {
    my ( $base_url, $actOnUser, $properties ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to update against!'; }
    if ( !defined $actOnUser ) { croak 'No user name defined to update!'; }
    my $property_post_vars =
      Apache::Sling::URL::properties_array_to_string($properties);
    my $post_variables = "\$post_variables = [";
    if ( $property_post_vars ne q{} ) {
        $post_variables .= "$property_post_vars";
    }
    $post_variables .= "]";
    return
"post $base_url/system/userManager/user/$actOnUser.update.html $post_variables";
}

#}}}

#{{{sub update_eval

=pod

=head2 update_eval

Check result of updateing user to the system.

=cut

sub update_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
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
