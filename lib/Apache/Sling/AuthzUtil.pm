#!/usr/bin/perl

package Apache::Sling::AuthzUtil;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.15';

#{{{imports
use strict;
use lib qw ( .. );
#}}}

#{{{sub get_acl_setup

=pod

=head2 get_acl_setup

Returns a textual representation of the request needed to retrieve the ACL for
a node in JSON format.

=cut

sub get_acl_setup {
    my ( $baseURL, $remoteDest ) = @_;
    die "No base url defined!" unless defined $baseURL;
    die "No destination to view ACL for defined!" unless defined $remoteDest;
    return "get $baseURL/$remoteDest.acl.json";
}
#}}}

#{{{sub get_acl_eval

=pod

=head2 get_acl_eval

Inspects the result returned from issuing the request generated in
get_acl_setup returning true if the result indicates the node ACL was returned
successfully, else false.

=cut

sub get_acl_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/ );
}
#}}}

#{{{sub delete_setup

=pod

=head2 delete_setup

Returns a textual representation of the request needed to retrieve the ACL for
a node in JSON format.

=cut

sub delete_setup {
    my ( $baseURL, $remoteDest, $principal ) = @_;
    die "No base url defined!" unless defined $baseURL;
    die "No destination to delete ACL for defined!" unless defined $remoteDest;
    die "No principal to delete ACL for defined!" unless defined $principal;
    my $postVariables = "\$postVariables = [':applyTo','$principal']";
    return "post $baseURL/$remoteDest.deleteAce.html $postVariables";
}
#}}}

#{{{sub delete_eval

=pod

=head2 delete_eval

Inspects the result returned from issuing the request generated in delete_setup
returning true if the result indicates the node ACL was deleted successfully,
else false.

=cut

sub delete_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/ );
}
#}}}

#{{{sub modify_privilege_setup

=pod

=head2 modify_privilege_setup

Returns a textual representation of the request needed to modify the privileges
on a node for a specific principal.

=cut

sub modify_privilege_setup {
    my ( $baseURL, $remoteDest, $principal, $grant_privileges, $deny_privileges ) = @_;
    die "No base url defined!" unless defined $baseURL;
    die "No destination to modify privilege for defined!" unless defined $remoteDest;
    die "No principal to modify privilege for defined!" unless defined $principal;
    my %privileges = (
        'read', 1,
        'modifyProperties', 1,
        'addChildNodes', 1,
        'removeNode', 1,
        'removeChildNodes', 1,
        'write', 1,
        'readAccessControl', 1,
        'modifyAccessControl', 1,
        'lockManagement', 1,
        'versionManagement', 1,
        'nodeTypeManagement', 1,
        'retentionManagement', 1,
        'lifecycleManagement', 1,
        'all', 1
    );
    my $postVariables = "\$postVariables = ['principalId','$principal',";
    foreach my $grant ( @{ $grant_privileges } ) {
        if ( $privileges{ $grant } ) {
            $postVariables .= "'privilege\@jcr:$grant','granted',";
	}
	else {
	    die "Unsupported privilege: \"$grant\" supplied!\n";
	}
    }
    foreach my $deny ( @{ $deny_privileges} ) {
        if ( $privileges{ $deny } ) {
            $postVariables .= "'privilege\@jcr:$deny','denied',";
	}
	else {
	    die "Unsupported privilege: \"$deny\" supplied!\n";
	}
    }
    $postVariables =~ s/,$/]/;
    return "post $baseURL/$remoteDest.modifyAce.html $postVariables";
}
#}}}

#{{{sub modify_privilege_eval

=pod

=head2 modify_privilege_eval

Inspects the result returned from issuing the request generated in
modify_privilege_setup returning true if the result indicates the privileges
were modified successfully, else false.

=cut

sub modify_privilege_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/ );
}
#}}}

1;

__END__

=head1 NAME

AuthzUtil - Utility library returning strings representing queries that perform
authz operations in the system.

=head1 ABSTRACT

AuthzUtil perl library essentially provides the request strings needed to
interact with authz functionality exposed over the system interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=cut
