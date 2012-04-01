#!/usr/bin/perl -w
package Apache::Sling;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::Authn;
use Apache::Sling::Authz;
use Apache::Sling::Content;
use Apache::Sling::Group;
use Apache::Sling::JsonQueryServlet;
use Apache::Sling::LDAPSynch;
use Apache::Sling::User;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.22';

#{{{sub new

sub new {
    my ( $class, $max_allowed_forks ) = @_;

    # control the maximum number of forks that can be
    # created when testing concurrency:
    $max_allowed_forks =
      ( defined $max_allowed_forks ? $max_allowed_forks : 32 );
    my $auth;
    my $authn;
    my $help;
    my $log;
    my $man;
    my $number_forks = 1;
    my $password;
    my $url;
    my $user;
    my $verbose;

    my $sling = {
        MaxForks => $max_allowed_forks,
        Auth     => $auth,
        Authn    => $authn,
        Help     => $help,
        Log      => $log,
        Man      => $man,
        Pass     => $password,
        Threads  => $number_forks,
        URL      => $url,
        User     => $user,
        Verbose  => $verbose
    };
    bless $sling, $class;
    return $sling;
}

#}}}

#{{{sub check_forks

sub check_forks {
    my ($sling) = @_;
    $sling->{'Threads'} = ( $sling->{'Threads'} || 1 );
    $sling->{'Threads'} =
      ( $sling->{'Threads'} =~ /^[0-9]+$/xms ? $sling->{'Threads'} : 1 );
    $sling->{'Threads'} =
      ( $sling->{'Threads'} < $sling->{'MaxForks'} ? $sling->{'Threads'} : 1 );
    return 1;
}

#}}}

#{{{sub authz_config

sub authz_config {
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

#{{{sub authz_run
sub authz_run {
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

#{{{sub content_config

sub content_config {
    my ($sling) = @_;
    my $add;
    my $additions;
    my $copy;
    my $delete;
    my $exists;
    my $filename;
    my $local;
    my $move;
    my @property;
    my $remote;
    my $remote_source;
    my $replace;
    my $view;

    my %content_config = (
        'auth'          => \$sling->{'Auth'},
        'help'          => \$sling->{'Help'},
        'log'           => \$sling->{'Log'},
        'man'           => \$sling->{'Man'},
        'pass'          => \$sling->{'Pass'},
        'threads'       => \$sling->{'Threads'},
        'url'           => \$sling->{'URL'},
        'user'          => \$sling->{'User'},
        'verbose'       => \$sling->{'Verbose'},
        'add'           => \$add,
        'additions'     => \$additions,
        'copy'          => \$copy,
        'delete'        => \$delete,
        'exists'        => \$exists,
        'filename'      => \$filename,
        'local'         => \$local,
        'move'          => \$move,
        'property'      => \@property,
        'remote'        => \$remote,
        'remote-source' => \$remote_source,
        'replace'       => \$replace,
        'view'          => \$view
    );

    return \%content_config;
}

#}}}

#{{{sub content_run
sub content_run {
    my ( $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No content config supplied!';
    }
    $sling->check_forks;
    ${ $config->{'remote'} } =
      Apache::Sling::URL::strip_leading_slash( ${ $config->{'remote'} } );
    ${ $config->{'remote-source'} } = Apache::Sling::URL::strip_leading_slash(
        ${ $config->{'remote-source'} } );
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : new Apache::Sling::Authn( \$sling );

    if ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding content from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message", $sling->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $sling->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a new separate user agent per fork in order to
                    # ensure cookie stores are separate, then log the user in:
                $authn->{'LWP'} = $authn->user_agent();
                $authn->login_user();
                my $content =
                  new Apache::Sling::Content( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $content->upload_from_file( ${ $config->{'additions'} },
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
        $authn->login_user();
        my $content =
          new Apache::Sling::Content( \$authn, $sling->{'Verbose'},
            $sling->{'Log'} );
        if (   defined ${ $config->{'local'} }
            && defined ${ $config->{'remote'} } )
        {
            $content->upload_file(
                ${ $config->{'local'} },
                ${ $config->{'remote'} },
                ${ $config->{'filename'} }
            );
        }
        elsif ( defined ${ $config->{'exists'} } ) {
            $content->check_exists( ${ $config->{'remote'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $content->add( ${ $config->{'remote'} }, $config->{'property'} );
        }
        elsif ( defined ${ $config->{'copy'} } ) {
            $content->copy(
                ${ $config->{'remote-source'} },
                ${ $config->{'remote'} },
                ${ $config->{'replace'} }
            );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $content->del( ${ $config->{'remote'} } );
        }
        elsif ( defined ${ $config->{'move'} } ) {
            $content->move(
                ${ $config->{'remote-source'} },
                ${ $config->{'remote'} },
                ${ $config->{'replace'} }
            );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $content->view( ${ $config->{'remote'} } );
        }
        Apache::Sling::Print::print_result($content);
    }
    return 1;
}

#}}}

#{{{sub group_config

sub group_config {
    my ($sling) = @_;
    my $additions;
    my $add;
    my $delete;
    my $exists;
    my @property;
    my $view;

    my %group_config = (
        'auth'      => \$sling->{'Auth'},
        'help'      => \$sling->{'Help'},
        'log'       => \$sling->{'Log'},
        'man'       => \$sling->{'Man'},
        'pass'      => \$sling->{'Pass'},
        'threads'   => \$sling->{'Threads'},
        'url'       => \$sling->{'URL'},
        'user'      => \$sling->{'User'},
        'verbose'   => \$sling->{'Verbose'},
        'add'       => \$add,
        'additions' => \$additions,
        'delete'    => \$delete,
        'exists'    => \$exists,
        'property'  => \@property,
        'view'      => \$view
    );

    return \%group_config;
}

#}}}

#{{{sub group_run
sub group_run {
    my ( $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No group config supplied!';
    }
    $sling->check_forks;
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : new Apache::Sling::Authn( \$sling );

    if ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding groups from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message", $sling->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $sling->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a new separate user agent per fork in order to
                    # ensure cookie stores are separate, then log the user in:
                $authn->{'LWP'} = $authn->user_agent();
                $authn->login_user();
                my $group =
                  new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $group->add_from_file( ${ $config->{'additions'} },
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
        $authn->login_user();
        my $group =
          new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
            $sling->{'Log'} );
        if ( defined ${ $config->{'exists'} } ) {
            $group->check_exists( ${ $config->{'exists'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $group->add( ${ $config->{'add'} }, $config->{'property'} );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $group->del( ${ $config->{'delete'} } );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $group->view( ${ $config->{'view'} } );
        }
        Apache::Sling::Print::print_result($group);
    }
    return 1;
}

#}}}

#{{{sub group_member_config

sub group_member_config {
    my ($sling) = @_;
    my $additions;
    my $add;
    my $delete;
    my $exists;
    my $group;
    my $view;

    my %group_member_config = (
        'auth'      => \$sling->{'Auth'},
        'help'      => \$sling->{'Help'},
        'log'       => \$sling->{'Log'},
        'man'       => \$sling->{'Man'},
        'pass'      => \$sling->{'Pass'},
        'threads'   => \$sling->{'Threads'},
        'url'       => \$sling->{'URL'},
        'user'      => \$sling->{'User'},
        'verbose'   => \$sling->{'Verbose'},
        'add'       => \$add,
        'additions' => \$additions,
        'delete'    => \$delete,
        'exists'    => \$exists,
        'group'     => \$group,
        'view'      => \$view
    );

    return \%group_member_config;
}

#}}}

#{{{sub group_member_run
sub group_member_run {
    my ( $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No group_member config supplied!';
    }
    $sling->check_forks;
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : new Apache::Sling::Authn( \$sling );

    if ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding groups from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message", $sling->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $sling->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a new separate user agent per fork in order to
                    # ensure cookie stores are separate, then log the user in:
                $authn->{'LWP'} = $authn->user_agent();
                $authn->login_user();
                my $group =
                  new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $group->member_add_from_file( ${ $config->{'additions'} },
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
        $authn->login_user();
        my $group =
          new Apache::Sling::Group( \$authn, $sling->{'Verbose'},
            $sling->{'Log'} );
        if ( defined ${ $config->{'exists'} } ) {
            $group->member_exists( ${ $config->{'group'} },
                ${ $config->{'exists'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $group->member_add( ${ $config->{'group'} },
                ${ $config->{'add'} } );
        }
        elsif ( defined ${ $config->{'delete'} } ) {
            $group->member_delete( ${ $config->{'group'} },
                ${ $config->{'delete'} } );
        }
        elsif ( defined ${ $config->{'view'} } ) {
            $group->member_view( ${ $config->{'group'} } );
        }
        Apache::Sling::Print::print_result($group);
    }
    return 1;
}

#}}}

#{{{sub json_query_servlet_config

sub json_query_servlet_config {
    my ($sling) = @_;
    my $all_nodes;

    my %json_query_servlet_config = (
        'auth'      => \$sling->{'Auth'},
        'help'      => \$sling->{'Help'},
        'log'       => \$sling->{'Log'},
        'man'       => \$sling->{'Man'},
        'pass'      => \$sling->{'Pass'},
        'threads'   => \$sling->{'Threads'},
        'url'       => \$sling->{'URL'},
        'user'      => \$sling->{'User'},
        'verbose'   => \$sling->{'Verbose'},
        'all_nodes' => \$all_nodes
    );

    return \%json_query_servlet_config;
}

#}}}

#{{{sub json_query_servlet_run
sub json_query_servlet_run {
    my ( $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No json query servlet config supplied!';
    }
    $sling->check_forks;
    ${ $config->{'remote'} } =
      Apache::Sling::URL::strip_leading_slash( ${ $config->{'remote'} } );
    ${ $config->{'remote-source'} } = Apache::Sling::URL::strip_leading_slash(
        ${ $config->{'remote-source'} } );

    my $authn = new Apache::Sling::Authn( \$sling );
    $authn->login_user();
    my $json_query_servlet =
      new Apache::Sling::JsonQueryServlet( \$authn, $sling->{'Verbose'},
        $sling->{'Log'} );
    if ( defined ${ $config->{'all_nodes'} } ) {
        $json_query_servlet->all_nodes();
    }
    Apache::Sling::Print::print_result($json_query_servlet);
    return 1;
}

#}}}

#{{{sub ldap_synch_config

sub ldap_synch_config {
    my ($sling) = @_;
    my $attributes;
    my $download_user_list;
    my $flag_disabled;
    my $ldap_attributes;
    my $ldap_base;
    my $ldap_dn;
    my $ldap_filter;
    my $ldap_host;
    my $ldap_pass;
    my $synch_full;
    my $synch_full_since;
    my $synch_listed;
    my $synch_listed_since;
    my $upload_user_list;

    my %ldap_synch_config = (
        'auth'               => \$sling->{'Auth'},
        'help'               => \$sling->{'Help'},
        'log'                => \$sling->{'Log'},
        'man'                => \$sling->{'Man'},
        'pass'               => \$sling->{'Pass'},
        'threads'            => \$sling->{'Threads'},
        'url'                => \$sling->{'URL'},
        'user'               => \$sling->{'User'},
        'verbose'            => \$sling->{'Verbose'},
        'attributes'         => $attributes,
        'download-user-list' => $download_user_list,
        'flag-disabled'      => $flag_disabled,
        'ldap-attributes'    => $ldap_attributes,
        'ldap-base'          => $ldap_base,
        'ldap-dn'            => $ldap_dn,
        'ldap-filter'        => $ldap_filter,
        'ldap-host'          => $ldap_host,
        'ldap-pass'          => $ldap_pass,
        'synch-full'         => $synch_full,
        'synch-full-since'   => $synch_full_since,
        'synch-listed'       => $synch_listed,
        'synch-listed-since' => $synch_listed_since,
        'upload-user-list'   => $upload_user_list
    );

    return \%ldap_synch_config;
}

#}}}

#{{{sub ldap_synch_run
sub ldap_synch_run {
    my ( $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No ldap_synch config supplied!';
    }
    $sling->check_forks;

    my $authn = new Apache::Sling::Authn( \$sling );
    $authn->login_user();
    my $ldap_synch = new Apache::Sling::LDAPSynch(
        ${ $config->{'ldap-host'} },
        ${ $config->{'ldap-base'} },
        ${ $config->{'ldap-filter'} },
        ${ $config->{'ldap-dn'} },
        ${ $config->{'ldap-pass'} },
        \$authn,
        ${ $config->{'flag-disabled'} },
        $sling->{'Verbose'},
        $sling->{'Log'}
    );
    if ( defined ${ $config->{'download-user-list'} } ) {
        $ldap_synch->download_synch_user_list(
            ${ $config->{'download-user-list'} } );
    }
    elsif ( defined ${ $config->{'upload-user-list'} } ) {
        $ldap_synch->upload_synch_user_list(
            ${ $config->{'upload-user-list'} } );
    }
    elsif ( defined ${ $config->{'synch-full'} } ) {
        $ldap_synch->synch_full( ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} } );
    }
    elsif ( defined ${ $config->{'synch-full-since'} } ) {
        $ldap_synch->synch_full_since(
            ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} },
            ${ $config->{'synch-full-since'} }
        );
    }
    elsif ( defined ${ $config->{'synch-listed'} } ) {
        $ldap_synch->synch_listed( ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} } );
    }
    elsif ( defined ${ $config->{'synch-listed-since'} } ) {
        $ldap_synch->synch_listed_since(
            ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} },
            ${ $config->{'synch-listed-since'} }
        );
    }
    Apache::Sling::Print::print_result($ldap_synch);
    return 1;
}

#}}}

#{{{sub user_config

sub user_config {
    my ($sling) = @_;
    my $password;
    my $additions;
    my $add;
    my $change_password;
    my $delete;
    my $email;
    my $exists;
    my $first_name;
    my $last_name;
    my $new_password;
    my @property;
    my $update;
    my $view;

    my %user_config = (
        'auth'            => \$sling->{'Auth'},
        'help'            => \$sling->{'Help'},
        'log'             => \$sling->{'Log'},
        'man'             => \$sling->{'Man'},
        'pass'            => \$sling->{'Pass'},
        'threads'         => \$sling->{'Threads'},
        'url'             => \$sling->{'URL'},
        'user'            => \$sling->{'User'},
        'verbose'         => \$sling->{'Verbose'},
        'add'             => \$add,
        'additions'       => \$additions,
        'change-password' => \$change_password,
        'delete'          => \$delete,
        'email'           => \$email,
        'exists'          => \$exists,
        'first-name'      => \$first_name,
        'last-name'       => \$last_name,
        'new-password'    => \$new_password,
        'password'        => \$password,
        'property'        => \@property,
        'update'          => \$update,
        'view'            => \$view
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
    my $authn =
      defined $sling->{'Authn'}
      ? ${ $sling->{'Authn'} }
      : new Apache::Sling::Authn( \$sling );

    # Handle the three special case commonly used properties:
    if ( defined ${ $config->{'email'} } ) {
        push @{ $config->{'property'} }, "email=" . ${ $config->{'email'} };
    }
    if ( defined ${ $config->{'first-name'} } ) {
        push @{ $config->{'property'} },
          "firstName=" . ${ $config->{'first-name'} };
    }
    if ( defined ${ $config->{'last-name'} } ) {
        push @{ $config->{'property'} },
          "lastName=" . ${ $config->{'last-name'} };
    }

    if ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding users from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message", $sling->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $sling->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a new separate user agent per fork in order to
                    # ensure cookie stores are separate, then log the user in:
                $authn->{'LWP'} = $authn->user_agent();
                $authn->login_user();
                my $user =
                  new Apache::Sling::User( \$authn, $sling->{'Verbose'},
                    $sling->{'Log'} );
                $user->add_from_file( ${ $config->{'additions'} },
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
        $authn->login_user();
        my $user =
          new Apache::Sling::User( \$authn, $sling->{'Verbose'},
            $sling->{'Log'} );
        if ( defined ${ $config->{'exists'} } ) {
            $user->check_exists( ${ $config->{'exists'} } );
        }
        elsif ( defined ${ $config->{'add'} } ) {
            $user->add(
                ${ $config->{'add'} },
                ${ $config->{'password'} },
                $config->{'property'}
            );
        }
        elsif ( defined ${ $config->{'update'} } ) {
            $user->update( ${ $config->{'update'} }, $config->{'property'} );
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

=head2 check_forks

Check number of forks to create complies with maximum number of forks
allowed.

=head2 authz_config

Fetch hash of authz configuration.

=head2 authz_run

Run authz related actions.

=head2 content_config

Fetch hash of content configuration.

=head2 content_run

Run content related actions.

=head2 group_config

Fetch hash of group configuration.

=head2 group_run

Run group related actions.

=head2 group_member_config

Fetch hash of group membership configuration.

=head2 group_member_run

Run group membership related actions.

=head2 json_query_servlet_config

Fetch hash of json query servlet configuration.

=head2 json_query_servlet_run

Run json query server related actions.

=head2 ldap_synch_config

Fetch hash of ldap synchronization configuration.

=head2 ldap_synch_run

Run ldap synchronization related actions.

=head2 user_config

Fetch hash of user configuration.

=head2 user_run

Run user related actions.

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

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
