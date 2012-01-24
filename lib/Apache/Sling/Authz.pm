#!/usr/bin/perl

package Apache::Sling::Authz;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::AuthzUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.17';

#{{{sub new

=pod

=head2 new

Create, set up, and return an Authz object.

=cut

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $content = {
        BaseURL  => $$authn->{'BaseURL'},
        Authn    => $authn,
        Message  => "",
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless( $content, $class );
    return $content;
}

#}}}

#{{{sub set_results

=pod

=head2 set_results

Populate the message and response with results returned from performing query:

=cut

sub set_results {
    my ( $content, $message, $response ) = @_;
    $content->{'Message'}  = $message;
    $content->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub get_acl

=pod

=head2 get_acl

Return the access control list for the node in JSON format

=cut

sub get_acl {
    my ( $content, $remoteDest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::AuthzUtil::get_acl_setup(
            $content->{'BaseURL'}, $remoteDest
        )
    );
    my $success = Apache::Sling::AuthzUtil::get_acl_eval($res);
    my $message =
      ( $success
        ? ${$res}->content
        : "Could not view ACL for \"$remoteDest\"" );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub modify_privileges

=pod

=head2 modify_privileges

Modify the privileges on a specified node for a specified principal.

=cut

sub modify_privileges {
    my ( $content, $remoteDest, $principal, $grant_privileges,
        $deny_privileges ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::AuthzUtil::modify_privilege_setup(
            $content->{'BaseURL'}, $remoteDest, $principal,
            $grant_privileges,     $deny_privileges
        )
    );
    my $success = Apache::Sling::AuthzUtil::modify_privilege_eval($res);
    my $message = "Privileges on \"$remoteDest\" for \"$principal\" ";
    $message .= ( $success ? "modified." : "were not modified." );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub delete

=pod

=head2 delete

Delete the access controls for a given principal on a given node:

=cut

sub delete {
    my ( $content, $remoteDest, $principal ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::AuthzUtil::delete_setup(
            $content->{'BaseURL'}, $remoteDest, $principal
        )
    );
    my $success = Apache::Sling::AuthzUtil::delete_eval($res);
    my $message = "Privileges on \"$remoteDest\" for \"$principal\" ";
    $message .= ( $success ? "removed." : "were not removed." );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Authz - content related functionality for Sling implemented over rest
APIs.

=head1 ABSTRACT

Perl library providing a layer of abstraction to the REST content methods

=head2 Available privliges

=over 

=item jcr:read - the privilege to retrieve a node and get its properties and their values.

=item jcr:modifyProperties - the privilege to create, modify and remove the properties of a node.

=item jcr:addChildNodes - the privilege to create child nodes of a node.

=item jcr:removeNode - the privilege to remove a node.

=item jcr:removeChildNodes the privilege to remove child nodes of a node.

=item jcr:write an aggregate privilege that contains:

 jcr:modifyProperties
 jcr:addChildNodes
 jcr:removeNode
 jcr:removeChildNodes

=item jcr:readAccessControl the privilege to get the access control policy of a node.

=item jcr:modifyAccessControl the privilege to modify the access control policies of a node.

=item jcr:lockManagement the privilege to lock and unlock a node.

=item jcr:versionManagment the privilege to perform versioning operations on a node.

=item jcr:nodeTypeManagement the privilege to add and remove mixin node types and change the primary node type of a node.

=item jcr:retentionManagement the privilege to perform retention management operations on a node.

=item jcr:lifecycleManagement the privilege to perform lifecycle operations on a node.

=item jcr:all an aggregate privilege that contains all predefined privileges.

 jcr:read
 jcr:write
 jcr:readAccessControl
 jcr:modifyAccessControl
 jcr:lockManagement
 jcr:versionManagement
 jcr:nodeTypeManagement
 jcr:retentionManagement
 jcr:lifecycleManagement

=back

Note: In order to actually remove a node, jcr:removeNode is required on that node and
jcr:removeChildNodes on the parent node. The distinction is provided in order
to reflect implementations that internally model "remove" as a "delete" instead
of an "unlink". A repository that uses the "delete" model can have
jcr:removeChildNodes in every access control policy, so that removal is
effectively controlled by jcr:removeNode.
