#!/usr/bin/perl

package Apache::Sling::Authz;

use 5.008001;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use Apache::Sling;
use Apache::Sling::AuthzUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = qw(command_line);

our $VERSION = '0.23';

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

#{{{ sub command_line
sub command_line {
    my @ARGV = @_;

    #options parsing
    my $sling  = Apache::Sling->new;
    my $config = config($sling);

    GetOptions(
        $config,            'auth=s',
        'help|?',           'log|L=s',
        'man|M',            'pass|p=s',
        'threads|t=s',      'url|U=s',
        'user|u=s',         'verbose|v+',
        'addChildNodes!',   'all!',
        'delete|d',         'lifecycleManage!',
        'lockManage!',      'modifyACL!',
        'modifyProps!',     'nodeTypeManage!',
        'principal|P=s',    'readACL!',
        'read!',            'remote|r=s',
        'removeChilds!',    'removeNode!',
        'retentionManage!', 'versionManage!',
        'view|V',           'write!'
    ) or pod2usage(2);

    if ( $sling->{'Help'} ) { help(); }
    if ( $sling->{'Man'} )  { man(); }

    run($sling, $config);
}

#}}}

#{{{sub config

sub config {
    my ($sling) = @_;
    my $delete;
    my $principal;
    my $remote_node;
    my $view;

    # privileges:
    my $add_child_nodes;
    my $all;
    my $life_cycle_manage;
    my $lock_manage;
    my $modify_acl;
    my $modify_props;
    my $node_type_manage;
    my $read;
    my $read_acl;
    my $remove_childs;
    my $remove_node;
    my $retention_manage;
    my $version_manage;
    my $write;

    my %authz_config = (
        'auth'            => \$sling->{'Auth'},
        'help'            => \$sling->{'Help'},
        'log'             => \$sling->{'Log'},
        'man'             => \$sling->{'Man'},
        'pass'            => \$sling->{'Pass'},
        'threads'         => \$sling->{'Threads'},
        'url'             => \$sling->{'URL'},
        'user'            => \$sling->{'User'},
        'verbose'         => \$sling->{'Verbose'},
        'addChildNodes'   => \$add_child_nodes,
        'all'             => \$all,
        'delete'          => \$delete,
        'lifecycleManage' => \$life_cycle_manage,
        'lockManage'      => \$lock_manage,
        'modifyACL'       => \$modify_acl,
        'modifyProps'     => \$modify_props,
        'nodeTypeManage'  => \$node_type_manage,
        'principal'       => \$principal,
        'readACL'         => \$read_acl,
        'read'            => \$read,
        'remote'          => \$remote_node,
        'removeChilds'    => \$remove_childs,
        'removeNode'      => \$remove_node,
        'retentionManage' => \$retention_manage,
        'versionManage'   => \$version_manage,
        'view'            => \$view,
        'write'           => \$write
    );

    return \%authz_config;
}

#}}}

#{{{sub del

=pod

=head2 del

Delete the access controls for a given principal on a given node:

=cut

sub del {
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
    my $message = (
        $success
        ? ${$res}->content
        : "Could not view ACL for \"$remoteDest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub help
sub help {

    print
"Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]\n";
    print "The following options are accepted:\n\n";

    print
" --auth (type)                  - Specify auth type. If ommitted, default is used.\n";
    print
" --delete or -d                 - delete access control list for node for principal.\n";
    print
" --help or -?                   - view the script synopsis and options.\n";
    print
" --log or -L (log)              - Log script output to specified log file.\n";
    print
      " --man or -M                    - view the full script documentation.\n";
    print
" --(no-)addChildNodes           - Grant or deny the addChildNodes privilege\n";
    print
      " --(no-)all                     - Grant or deny all above privileges\n";
    print
" --(no-)modifyACL               - Grant or deny the modifyACL privilege\n";
    print
" --(no-)modifyProps             - Grant or deny the modifyProperties privilege\n";
    print
      " --(no-)readACL                 - Grant or deny the readACL privilege\n";
    print
      " --(no-)read                    - Grant or deny the read privilege\n";
    print
" --(no-)removeChilds            - Grant or deny the removeChildNodes privilege\n";
    print
" --(no-)removeNode              - Grant or deny the removeNode privilege\n";
    print
      " --(no-)write                   - Grant or deny the write privileges:\n";
    print
"                                  modifyProperties,addChildNodes,removeNode,removeChildNodes\n";
    print
" --pass or -p (password)        - Password of user performing content manipulations.\n";
    print
" --principal or -P (principal)  - Principal to grant, deny, or delete privilege for.\n";
    print
" --remote or -r (remoteNode)    - specify remote node under JCR root to act on.\n";
    print
" --url or -U (URL)              - URL for system being tested against.\n";
    print
" --user or -u (username)        - Name of user to perform content manipulations as.\n";
    print " --verbose or -v or -vv or -vvv - Increase verbosity of output.\n";
    print
" --view or -V                   - view access control list for node.\n\n";
    print "Options may be merged together. -- stops processing of options.\n";
    print "Space is not required between options and their arguments.\n";
    print "For full details run: perl $0 --man\n";

    return 1;
}

#}}}

#{{{ sub man
sub man {

    print
"authz perl script. Provides a means of manipulating access control on content\n";
    print
"in sling from the command line. This script can be used to get, set, update and\n";
    print
"delete content permissions. It also acts as a reference implementation for the\n";
    print "Authz perl library.\n\n";

    help();

    print "\n* Authenticate and view the ACL for the /data node:\n\n";

    print " perl $0 -U http://localhost:8080 -r /data -V -u admin -p admin\n\n";

    print
"* Authenticate and grant the read privilege to the owner principal, view the result:\n\n";

    print
" perl $0 -U http://localhost:8080 -r /testdata -P owner --read -u admin -p admin -V\n\n";

    print
"* Authenticate and grant the modifyProps privilege to the everyone principal, * view the result:\n\n";

    print
" perl $0 -U http://localhost:8080 -r /testdata -P everyone --modifyProps -u admin -p admin -V\n\n";

    print
"* Authenticate and deny the addChildNodes privilege to the testuser principal, * view the result:\n\n";

    print
" perl $0 -U http://localhost:8080 -r /testdata -P testuser --no-addChildNodes -u admin -p admin -V\n\n";

    print
"* Authenticate with form based authentication and grant the read and write privileges to the g-testgroup principal, log the results, including the resulting JSON, to authz.log:\n\n";

    print
" perl $0 -U http://localhost:8080 -r /testdata -P g-testgroup --read --write -u admin -p admin --auth form -V -L authz.log\n\n";

    print "JSR-283 privileges:\n\n";

    print
      "The following privileges are not yet supported, but may be soon:\n\n";

    print
      " --(no-)lockManage      - Grant or deny the lockManagement privilege\n";
    print
" --(no-)versionManage   - Grant or deny the versionManagement privilege\n";
    print
" --(no-)nodeTypeManage  - Grant or deny the nodeTypeManagement privilege\n";
    print
" --(no-)retentionManage - Grant or deny the retentionManagement privilege\n";
    print
" --(no-)lifecycleManage - Grant or deny the lifeCycleManagement privilege\n";
    return 1;
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

#{{{sub run
sub run {
    my ( $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No authz config supplied!';
    }
    $sling->check_forks;
    ${ $config->{'remote'} } =
      Apache::Sling::URL::strip_leading_slash( ${ $config->{'remote'} } );

    my $authn = new Apache::Sling::Authn( \$sling );
    $authn->login_user();
    my $authz =
      new Apache::Sling::Authz( \$authn, $sling->{'Verbose'}, $sling->{'Log'} );
    if ( defined ${ $config->{'delete'} } ) {
        $authz->del( ${ $config->{'remote'} }, ${ $config->{'principal'} } );
        Apache::Sling::Print::print_result($authz);
    }
    my @grant_privileges;
    my @deny_privileges;
    if ( defined ${ $config->{'read'} } ) {
        ${ $config->{'read'} }
          ? push @grant_privileges, 'read'
          : push @deny_privileges, 'read';
    }
    if ( defined ${ $config->{'modifyProps'} } ) {
        ${ $config->{'modifyProps'} }
          ? push @grant_privileges, 'modifyProperties'
          : push @deny_privileges, 'modifyProperties';
    }
    if ( defined ${ $config->{'addChildNodes'} } ) {
        ${ $config->{'addChildNodes'} }
          ? push @grant_privileges, 'addChildNodes'
          : push @deny_privileges, 'addChildNodes';
    }
    if ( defined ${ $config->{'removeNode'} } ) {
        ${ $config->{'removeNode'} }
          ? push @grant_privileges, 'removeNode'
          : push @deny_privileges, 'removeNode';
    }
    if ( defined ${ $config->{'removeChilds'} } ) {
        ${ $config->{'removeChilds'} }
          ? push @grant_privileges, 'removeChildNodes'
          : push @deny_privileges, 'removeChildNodes';
    }
    if ( defined ${ $config->{'write'} } ) {
        ${ $config->{'write'} }
          ? push @grant_privileges, 'write'
          : push @deny_privileges, 'write';
    }
    if ( defined ${ $config->{'readACL'} } ) {
        ${ $config->{'readACL'} }
          ? push @grant_privileges, 'readAccessControl'
          : push @deny_privileges, 'readAccessControl';
    }
    if ( defined ${ $config->{'modifyACL'} } ) {
        ${ $config->{'modifyACL'} }
          ? push @grant_privileges, 'modifyAccessControl'
          : push @deny_privileges, 'modifyAccessControl';
    }

# Privileges that may become available in due course:
# if ( defined $lock_manage ) {
# $lock_manage ? push ( @grant_privileges, 'lockManagement' ) : push ( @deny_privileges, 'lockManagement' );
# }
# if ( defined $version_manage ) {
# $version_manage ? push ( @grant_privileges, 'versionManagement' ) : push ( @deny_privileges, 'versionManagement' );
# }
# if ( defined $node_type_manage ) {
# $node_type_manage ? push ( @grant_privileges, 'nodeTypeManagement' ) : push ( @deny_privileges, 'nodeTypeManagement' );
# }
# if ( defined $retention_manage ) {
# $retention_manage ? push ( @grant_privileges, 'retentionManagement' ) : push ( @deny_privileges, 'retentionManagement' );
# }
# if ( defined $life_cycle_manage ) {
# $life_cycle_manage ? push ( @grant_privileges, 'lifecycleManagement' ) : push ( @deny_privileges, 'lifecycleManagement' );
# }
    if ( defined ${ $config->{'all'} } ) {
        ${ $config->{'all'} }
          ? push @grant_privileges, 'all'
          : push @deny_privileges, 'all';
    }
    if ( @grant_privileges || @deny_privileges ) {
        $authz->modify_privileges(
            ${ $config->{'remote'} }, ${ $config->{'principal'} },
            \@grant_privileges,       \@deny_privileges
        );
        Apache::Sling::Print::print_result($authz);
    }
    if ( defined ${ $config->{'view'} } ) {
        $authz->get_acl( ${ $config->{'remote'} } );
        Apache::Sling::Print::print_result($authz);
    }

    return 1;
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

=head2 config

Fetch hash of authz configuration.

=head2 run

Run authz related actions.

