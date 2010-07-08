#!/usr/bin/perl

package Apache::Sling::GroupUtil;

use 5.008008;
use strict;
use warnings;
use Carp;
use Apache::Sling::URL;

=head1 NAME

GroupUtil - Utility library returning strings representing Rest queries that
perform group related actions in the system.

=head1 ABSTRACT

GroupUtil perl library essentially provides the request strings needed to
interact with group functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=cut

#{{{sub add_setup

=pod

=head2 add_setup

Returns a textual representation of the request needed to add the group to the
system.

=cut

sub add_setup {
    my ( $baseURL, $actOnGroup, $properties ) = @_;
    croak "No base url defined to add against!" unless defined $baseURL;
    croak "No group name defined to add!" unless defined $actOnGroup;
    my $property_post_vars = Apache::Sling::URL::properties_array_to_string( $properties );
    my $postVariables = "\$postVariables = [':name','$actOnGroup'";
    if ( defined $property_post_vars && $property_post_vars !~ /^$/x ) {
        $postVariables .= ",$property_post_vars";
    }
    $postVariables .= "]";
    return "post $baseURL/system/userManager/group.create.html $postVariables";
}
#}}}

#{{{sub add_eval

=pod

=head2 add_eval

Check result of adding group to the system.

=cut

sub add_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/x );
}
#}}}

#{{{sub delete_setup

=pod

=head2 delete_setup

Returns a textual representation of the request needed to delete the group from
the system.

=cut

sub delete_setup {
    my ( $baseURL, $actOnGroup ) = @_;
    croak "No base url defined to delete against!" unless defined $baseURL;
    croak "No group name defined to delete!" unless defined $actOnGroup;
    my $postVariables = "\$postVariables = []";
    return "post $baseURL/system/userManager/group/$actOnGroup.delete.html $postVariables";
}
#}}}

#{{{sub delete_eval

=pod

=head2 delete_eval

Check result of deleting group from the system.

=cut

sub delete_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/x );
}
#}}}

#{{{sub exists_setup

=pod

=head2 exists_setup

Returns a textual representation of the request needed to test whether a given
group exists in the system.

=cut

sub exists_setup {
    my ( $baseURL, $actOnGroup ) = @_;
    croak "No base url to check existence against!" unless defined $actOnGroup;
    croak "No group to check existence of defined!" unless defined $actOnGroup;
    return "get $baseURL/system/userManager/group/$actOnGroup.json";
}
#}}}

#{{{sub exists_eval

=pod

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the group does exist in the system, else
false.

=cut

sub exists_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/x );
}
#}}}

#{{{sub member_add_setup

=pod

=head2 member_add_setup

Returns a textual representation of the request needed to add add a member to a
group in the system.

=cut

sub member_add_setup {
    my ( $baseURL, $actOnGroup, $addMember ) = @_;
    croak "No base url defined to add against!" unless defined $baseURL;
    croak "No group name defined to add member to!" unless defined $actOnGroup;
    croak "No member name defined to add!" unless defined $addMember;
    my $postVariables = "\$postVariables = [':member','/system/userManager/user/$addMember']";
    return "post $baseURL/system/userManager/group/$actOnGroup.update.html $postVariables";
}
#}}}

#{{{sub member_add_eval

=pod

=head2 member_add_eval

Check result of adding a member to a group in the system.

=cut

sub member_add_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/x );
}
#}}}

#{{{sub member_delete_setup

=pod

=head2 member_delete_setup

Returns a textual representation of the request needed to delete a member from
a group in the system.

=cut

sub member_delete_setup {
    my ( $baseURL, $actOnGroup, $deleteMember ) = @_;
    croak "No base url defined to delete against!" unless defined $baseURL;
    croak "No group name defined to delete member to!" unless defined $actOnGroup;
    croak "No member name defined to delete!" unless defined $deleteMember;
    my $postVariables = "\$postVariables = [':member\@Delete','/system/userManager/user/$deleteMember']";
    return "post $baseURL/system/userManager/group/$actOnGroup.update.html $postVariables";
}
#}}}

#{{{sub member_delete_eval

=pod

=head2 member_delete_eval

Check result of deleting a member from a group in the system.

=cut

sub member_delete_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/x && $$res->content !~ /^$/x );
}
#}}}

#{{{sub view_setup

=pod

=head2 view_setup

Returns a textual representation of the request needed to view a given group in
the system. This function is similar to exists expect authentication is forced.

=cut

sub view_setup {
    my ( $baseURL, $actOnGroup ) = @_;
    croak "No base url to view with defined!" unless defined $baseURL;
    croak "No group to view defined!" unless defined $actOnGroup;
    return "get $baseURL/system/userManager/group/$actOnGroup.tidy.json";
}
#}}}

#{{{sub view_eval

=pod

=head2 view_eval

Inspects the result returned from issuing the request generated in view_setup
returning true if the result indicates the group view was returned, else false.

=cut

sub view_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/x && $$res->content !~ /^$/x );
}
#}}}

1;
