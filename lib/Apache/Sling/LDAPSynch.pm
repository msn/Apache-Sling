#!/usr/bin/perl

package Apache::Sling::LDAPSynch;

use 5.008008;
use strict;
use warnings;
use Carp;
use Apache::Sling::Authn;
use Apache::Sling::Content;
use Apache::Sling::User;
use Data::Dumper;
use Fcntl ':flock';
use File::Temp;
use Net::LDAP;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.07';

=head1 NAME

LDAPSynch - Synchronize users from an external LDAP server with the internal
users in an Apache Sling instance.

=head1 ABSTRACT

Perl library providing a means to synchronize users from an external LDAP
server with the internal users in an Apache Sling instance.

=head2 Methods

=cut

#{{{sub new

=pod

=head2 new

Create, set up, and return an LDAPSynch object.

=cut

sub new {
    my (
        $class,      $ldap_host,  $ldap_base,  $filter,
        $dn,         $pass,       $sling_host, $sling_user,
        $sling_pass, $sling_auth, $verbose,    $log
    ) = @_;
    $filter  = ( defined $filter  ? $filter  : q(uid) );
    $verbose = ( defined $verbose ? $verbose : 0 );

    # Directory containing the cache and user_list files:
    my $synch_cache_path =
      q(_user/a/ad/admin/private/ldap_synch_cache_system_files);

    # Directory containing backups of the cache and user_list files:
    my $synch_cache_backup_path =
      q(_user/a/ad/admin/private/ldap_synch_cache_system_files_backup);

# List of specific users previously ingested in to the sling system and their status:
    my $synch_cache_file = q(cache.txt);

   # List of specific ldap users that are to be ingested in to the sling system:
    my $synch_user_list = q(user_list.txt);
    my $ldap;
    my $authn =
      new Apache::Sling::Authn( $sling_host, $sling_user, $sling_pass,
        $sling_auth, $verbose, $log )
      or croak q(Problem with Sling instance authentication!);
    my $content = new Apache::Sling::Content( \$authn, $verbose, $log )
      or croak q(Problem creating Sling content object!);
    my $user = new Apache::Sling::User( \$authn, $verbose, $log )
      or croak q(Problem creating Sling user object!);
    my $ldap_synch = {
        CacheBackupPath => $synch_cache_backup_path,
        CachePath       => $synch_cache_path,
        CacheFile       => $synch_cache_file,
        Content         => \$content,
        LDAP            => \$ldap,
        LDAPbase        => $ldap_base,
        LDAPDN          => $dn,
        LDAPHost        => $ldap_host,
        LDAPPass        => $pass,
        Filter          => $filter,
        Log             => $log,
        Message         => q(),
        User            => \$user,
        UserList        => $synch_user_list,
        Verbose         => $verbose
    };
    bless $ldap_synch, $class;
    return $ldap_synch;
}

#}}}

#{{{sub ldap_connect

=head2 ldap_connect

Connect to the ldap server.

=cut

sub ldap_connect {
    my ($class) = @_;
    $class->{'LDAP'} = Net::LDAP->new( $class->{'LDAPHost'} )
      or croak 'Problem opening a connection to the LDAP server!';
    if ( defined $class->{'LDAPDN'} && defined $class->{'LDAPPASS'} ) {
        my $mesg = $class->{'LDAP'}->bind(
            $class->{'LDAPDN'},
            password => $class->{'LDAPPASS'},
            version  => '3'
        ) or croak 'Problem with authenticated bind to LDAP server!';
    }
    else {
        my $mesg = $class->{'LDAP'}->bind( version => '3' )
          or croak 'Problem with anonymous bind to LDAP server!';
    }
    return 1;
}

#}}}

#{{{sub ldap_search

=head2 ldap_search

Perform an ldap search.

=cut

sub ldap_search {
    my ( $class, $search, $attrs ) = @_;
    $class->ldap_connect;
    return $class->{'LDAP'}->search(
        base   => $class->{'LDAPbase'},
        scope  => 'sub',
        filter => "$search",
        attrs  => $attrs
    )->as_struct;
}

#}}}

#{{{sub init_synch_cache

=head2 init_synch_cache

Initialize the Apache Sling synch cache.

=cut

sub init_synch_cache {
    my ($class) = @_;
    if ( !${ $class->{'Content'} }
        ->check_exists( $class->{'CachePath'} . q(/) . $class->{'CacheFile'} ) )
    {
        my ( $tmp_cache_file_handle, $tmp_cache_file_name ) =
          File::Temp::tempfile();
        my %synch_cache;
        print {$tmp_cache_file_handle}
          Data::Dumper->Dump( [ \%synch_cache ], [qw( synch_cache )] )
          or croak q(Unable to print initial data dump of synch cache to file!);
        close $tmp_cache_file_handle
          or croak
q(Problem closing temporary file handle when initializing synch cache);
        ${ $class->{'Content'} }
          ->upload_file( $tmp_cache_file_name, $class->{'CachePath'},
            $class->{'CacheFile'} )
          or croak q(Unable to initialize LDAP synch cache file!);
        unlink $tmp_cache_file_name
          or croak
          q(Problem clearing up temporary file after init of synch cache!);
    }
    return 1;
}

#}}}

#{{{sub get_synch_cache

=head2 get_synch_cache

Fetch the synchronization cache file.

=cut

sub get_synch_cache {
    my ($class) = @_;
    $class->init_synch_cache();
    if ( !${ $class->{'Content'} }
        ->check_exists( $class->{'CachePath'} . q(/) . $class->{'CacheFile'} ) )
    {
        croak q(No synch cache file present - initialization must have failed!);
    }
    ${ $class->{'Content'} }
      ->view_file( $class->{'CachePath'} . q(/) . $class->{'CacheFile'} )
      or croak q(Problem viewing synch cache file);
    my $synch_cache;
    my $success = eval ${ $class->{'Content'} }->{'Message'};
    if ( !defined $success ) {
        croak "Error \"$@\" parsing synchronized cache dump.";
    }
    return $synch_cache;
}

#}}}

#{{{sub update_synch_cache

=head2 update_synch_cache

Update the synchronization cache file with the latest state.

=cut

sub update_synch_cache {
    my ( $class, $synch_cache ) = @_;
    my ( $tmp_cache_file_handle, $tmp_cache_file_name ) =
      File::Temp::tempfile();
    print {$tmp_cache_file_handle}
      Data::Dumper->Dump( [$synch_cache], [qw( synch_cache )] )
      or croak q(Unable to print data dump of synch cache to file!);
    close $tmp_cache_file_handle
      or croak
      q(Problem closing temporary file handle when updating synch cache);
    ${ $class->{'Content'} }
      ->upload_file( $tmp_cache_file_name, $class->{'CachePath'},
        $class->{'CacheFile'} )
      or croak q(Unable to update LDAP synch cache file!);
    my $time = time;
    ${ $class->{'Content'} }
      ->upload_file( $tmp_cache_file_name, $class->{'CacheBackupPath'},
        "cache$time.txt" )
      or croak q(Unable to create LDAP synch cache backup file!);
    unlink $tmp_cache_file_name
      or croak
      q(Problem clearing up temporary file after updating synch cache!);
    return 1;
}

#}}}

#{{{sub get_synch_user_list

=head2 get_synch_user_list

Fetch the synchronization user list file.

=cut

sub get_synch_user_list {
    my ($class) = @_;
    if ( !${ $class->{'Content'} }
        ->check_exists( $class->{'CachePath'} . q(/) . $class->{'UserList'} ) )
    {
        croak q(No user list file present - you need to create one!);
    }
    ${ $class->{'Content'} }
      ->view_file( $class->{'CachePath'} . q(/) . $class->{'UserList'} )
      or croak q(Problem viewing synch user list);
    my $synch_user_list;
    my $success = eval ${ $class->{'Content'} }->{'Message'};
    if ( !defined $success ) {
        croak "Error \"$@\" parsing synchronized user list dump.";
    }
    return $synch_user_list;
}

#}}}

#{{{sub update_synch_user_list

=head2 update_synch_user_list

Update the synchronization user_list file with the latest state.

=cut

sub update_synch_user_list {
    my ( $class, $synch_user_list ) = @_;
    my ( $tmp_user_list_file_handle, $tmp_user_list_file_name ) =
      File::Temp::tempfile();
    print {$tmp_user_list_file_handle}
      Data::Dumper->Dump( [$synch_user_list], [qw( synch_user_list )] )
      or croak q(Unable to print data dump of synch user list to file!);
    close $tmp_user_list_file_handle
      or croak
      q(Problem closing temporary file handle when writing synch user list);
    ${ $class->{'Content'} }
      ->upload_file( $tmp_user_list_file_name, $class->{'CachePath'},
        $class->{'UserList'} )
      or croak
      q(Unable to upload LDAP synch user list file into sling instance!);
    Apache::Sling::Print::print_result( ${ $class->{'Content'} } );
    my $time = time;
    ${ $class->{'Content'} }
      ->upload_file( $tmp_user_list_file_name, $class->{'CacheBackupPath'},
        "user_list$time.txt" )
      or croak q(Unable to create LDAP synch user list backup file!);
    unlink $tmp_user_list_file_name
      or croak
      q(Problem clearing up temporary file after updating synch user list!);
    return 1;
}

#}}}

#{{{sub download_synch_user_list

=head2 download_synch_user_list

Download the current synchronization user list file.

=cut

sub download_synch_user_list {
    my ( $class, $user_list_file ) = @_;
    my $synch_user_list = $class->get_synch_user_list;
    foreach my $user ( sort( keys %{$synch_user_list} ) ) {
        if ( open my $out, '>>', $user_list_file ) {
            flock $out, LOCK_EX;
            print {$out} $user . "\n"
              or croak
              q(Problem printing when downloading synchronized user list!);
            flock $out, LOCK_UN;
            close $out
              or croak
q(Problem closing file handle when downloading synchronized user list!);
        }
        else {
            croak q(Could not open file to download synchronized user list to!);
        }
    }
    $class->{'Message'} =
      "Successfully downloaded user list to $user_list_file!";
    return 1;
}

#}}}

#{{{sub upload_synch_user_list

=head2 upload_synch_user_list

Upload a list of users to be synchronized into the sling system.

=cut

sub upload_synch_user_list {
    my ( $class, $user_list_file ) = @_;
    my %user_list_hash;
    if ( open my ($input), '<', $user_list_file ) {
        while (<$input>) {
            chomp;
            $user_list_hash{$_} = 1;
        }
        close $input or croak q(Problem closing upload user list file handle!);
    }
    else {
        croak q(Unable to open synch user list file to parse for upload!);
    }
    $class->update_synch_user_list( \%user_list_hash );
    $class->{'Message'} =
q(Successfully uploaded user list for use in subsequent synchronizations!);
    return 1;
}

#}}}

#{{{sub parse_attributes

=head2 parse_attributes

Read the given ldap and sling attributes into two separate specified arrays.
Check that the length of the arrays match.

=cut

sub parse_attributes {
    my ( $ldap_attrs, $sling_attrs, $ldap_attrs_array, $sling_attrs_array ) =
      @_;
    if ( defined $ldap_attrs ) {
        @{$ldap_attrs_array} = split ',', $ldap_attrs;
    }
    if ( defined $sling_attrs ) {
        @{$sling_attrs_array} = split ',', $sling_attrs;
    }
    if ( @{$ldap_attrs_array} != @{$sling_attrs_array} ) {
        croak
          q(Number of ldap attributes must match number of sling attributes, )
          . @{$ldap_attrs_array} . " != "
          . @{$sling_attrs_array};
    }
    return 1;
}

#}}}

#{{{sub check_for_property_modifications

=head2 check_for_property_modifications

Compare a new property hash with a cached version. If any changes to properties
have been made, then return true. Else return false.

=cut

sub check_for_property_modifications {
    my ( $new_properties, $cached_properties ) = @_;
    foreach my $property_key ( keys %$new_properties ) {
        if ( !defined $cached_properties->{$property_key} ) {

            # Found a newly specified property:
            return 1;
        }
        if ( $new_properties->{$property_key} ne
            $cached_properties->{$property_key} )
        {

            # Found a modified property:
            return 1;
        }
    }
    return 0;
}

#}}}

#{{{sub perform_synchronization

=head2 perform_synchronization

=cut

sub perform_synchronization {
    my ( $class, $arrayOfDNs, $search_result, $seen_user_ids, $synch_cache,
        $ldap_attrs_array, $sling_attrs_array )
      = @_;
    foreach my $dn ( @{$arrayOfDNs} ) {
        my $valref  = $search_result->{$dn};
        my $index   = 0;
        my $user_id = @{ $valref->{ $class->{'Filter'} } }[0];
        $seen_user_ids->{$user_id} = 1;
        my @properties_array;
        my %properties_hash;
        foreach my $ldap_attr (@$ldap_attrs_array) {
            my $value = @{ $valref->{$ldap_attr} }[0];
            if ( defined $value ) {
                push @properties_array,
                  @$sling_attrs_array[$index] . q(=) . $value;
                $properties_hash{ @$sling_attrs_array[$index] } = $value;
            }
            $index++;
        }
        if ( defined $synch_cache->{$user_id} ) {

            # We already know about this user from a previous run:
            if ( $synch_cache->{$user_id}->{'sakai:disabled'} eq '1' ) {

                # User was previously disabled. Re-enabling:
                push @properties_array, q(sakai:disabled=0);
                print "Re-enabling previously disabled user: $user_id\n";
                ${ $class->{'User'} }->update( $user_id, \@properties_array )
                  or croak q(Problem re-enabling user in sling instance!);
                $synch_cache->{$user_id} = \%properties_hash;
                $synch_cache->{$user_id}->{'sakai:disabled'} = '0';
            }
            else {

                # User is enabled in sling already, check for modifications:
                if (
                    check_for_property_modifications(
                        \%properties_hash, \%{ $synch_cache->{$user_id} }
                    )
                  )
                {

                    # Modifications are present, so we need to update:
                    print "Updating existing user $user_id\n";
                    ${ $class->{'User'} }
                      ->update( $user_id, \@properties_array )
                      or croak q(Problem updating user in sling instance!);
                    $properties_hash{'sakai:disabled'} = '0';
                    $synch_cache->{$user_id} = \%properties_hash;
                }
                else {

                    # No modifications present, nothing to do!
                    print "No user modifications, skipping: $user_id\n";
                }
            }
        }
        else {

            # We have never seen this user before:
            print "Creating new user: $user_id\n";
            ${ $class->{'User'} }
              ->add( $user_id, "password", \@properties_array )
              or croak q(Problem adding new user to sling instance!);
            $properties_hash{'sakai:disabled'} = '0';
            $synch_cache->{$user_id} = \%properties_hash;
        }
    }
    return 0;
}

#}}}

#{{{sub synch_full

=head2 synch_full

Perform a full synchronization of Sling internal users with the external LDAP
users.

=cut

sub synch_full {
    my ( $class, $ldap_attrs, $sling_attrs ) = @_;
    my $search = q{(} . $class->{'Filter'} . q{=*)};
    my @ldap_attrs_array;
    my @sling_attrs_array;
    parse_attributes( $ldap_attrs, $sling_attrs, \@ldap_attrs_array,
        \@sling_attrs_array )
      or croak q(Problem parsing attributes!);

    # We need to capture the id as well as any attributes:
    unshift @ldap_attrs_array, $class->{'Filter'};
    my $search_result = $class->ldap_search( $search, \@ldap_attrs_array );
    shift @ldap_attrs_array;

    my $synch_cache = $class->get_synch_cache;
    my %seen_user_ids;

    # process each DN using it as a key
    my @arrayOfDNs = sort ( keys %$search_result );

    $class->perform_synchronization( \@arrayOfDNs, $search_result,
        \%seen_user_ids, $synch_cache, \@ldap_attrs_array,
        \@sling_attrs_array );

    # Clean up records no longer in ldap:
    my @disable_property;
    push @disable_property, "sakai:disabled=1";
    foreach my $cache_entry ( sort( keys %{$synch_cache} ) ) {
        if ( $synch_cache->{$cache_entry}->{'sakai:disabled'} eq '0'
            && !defined $seen_user_ids{$cache_entry} )
        {
            print
"Disabling user record in sling that no longer exists in ldap: $cache_entry\n";
            ${ $class->{'User'} }->update( $cache_entry, \@disable_property )
              or croak q(Problem disabling user in sling instance!);
            $synch_cache->{$cache_entry}->{'sakai:disabled'} = '1';
        }
    }
    $class->update_synch_cache($synch_cache);

    $class->{'Message'} = "Successfully performed a full synchronization!";
    return 1;
}

#}}}

#{{{sub synch_full_since

=head2 synch_full_since

Perform a synchronization of Sling internal users with the external LDAP users,
using LDAP changes since a given timestamp.

=cut

sub synch_since {
    my ( $class, $ldap_attrs, $sling_attrs, $synch_since ) = @_;
    my $search = q{(modifytimestamp>=} . $synch_since . q{)};
    my $search_result = $class->ldap_search( $search, $ldap_attrs );
    croak q(Function not yet fully supported!);
    return 1;
}

#}}}

#{{{sub synch_listed

=pod

=head2 synch_listed

Perform a synchronization of Sling internal users with the external LDAP users
for a set of users listed in a specified file.

=cut

sub synch_listed {
    my ( $class, $ldap_attrs, $sling_attrs ) = @_;
    my $search = q{(} . $class->{'Filter'} . q{=*)};
    my $search_result = $class->ldap_search( $search, $ldap_attrs );
    croak q(Function not yet fully supported!);
    return 1;
}

#}}}

#{{{sub synch_listed_since

=head2 synch_listed_since

Perform a synchronization of Sling internal users with the external LDAP users,
using LDAP changes since a given timestamp for a set of users listed in a
specified file.

=cut

sub synch_listed_since {
    my ( $class, $ldap_attrs, $sling_attrs, $synch_since ) = @_;
    my $search = q{(} . $class->{'Filter'} . q{=*)};
    my $search_result = $class->ldap_search( $search, $ldap_attrs );
    croak q(Function not yet fully supported!);
    return 1;
}

#}}}

1;
