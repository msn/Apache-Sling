#!/usr/bin/perl

package Apache::Sling::Group;

use 5.008008;
use strict;
use warnings;
use Carp;
use JSON;
use Text::CSV;
use Apache::Sling::GroupUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.05';

=head1 NAME

Group - group related functionality for Sling implemented over rest
APIs.

=head1 ABSTRACT

Perl library providing a layer of abstraction to the REST group methods

=cut

#{{{sub new

=pod

=head2 new

Create, set up, and return a Group Object.

=cut

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    croak "no authn provided!" unless defined $authn;
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $group = { BaseURL => $$authn->{ 'BaseURL' },
                  Authn => $authn,
		  Message => "",
		  Response => \$response,
		  Verbose => $verbose,
		  Log => $log };
    bless( $group, $class );
    return $group;
}
#}}}

#{{{sub set_results
sub set_results {
    my ( $group, $message, $response ) = @_;
    $group->{ 'Message' } = $message;
    $group->{ 'Response' } = $response;
    return 1;
}
#}}}

#{{{sub add
sub add {
    my ( $group, $actOnGroup, $properties ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::add_setup( $group->{ 'BaseURL' }, $actOnGroup, $properties ) );
    my $success = Apache::Sling::GroupUtil::add_eval( $res );
    my $message = "Group: \"$actOnGroup\" ";
    $message .= ( $success ? "added!" : "was not added!" );
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

#{{{sub add_from_file
sub add_from_file {
    my ( $group, $file, $forkId, $numberForks ) = @_;
    my $csv = Text::CSV->new();
    my $count = 0;
    my $numberColumns = 0;
    my @column_headings;
    if ( open my ($input), "<", $file ) {
        while ( <$input> ) {
            if ( $count++ == 0 ) {
	        # Parse file column headings first to determine field names:
	        if ( $csv->parse( $_ ) ) {
	            @column_headings = $csv->fields();
		    # First field must be group:
		    if ( $column_headings[0] !~ /^group$/ix ) {
		        croak "First CSV column must be the group ID, ".
		            "column heading must be \"group\". ".
		            "Found: \"" . $column_headings[0] . "\".\n";
		    }
		    $numberColumns = @column_headings;
	        }
	        else {
	            croak "CSV broken, failed to parse line: " . $csv->error_input;
	        }
	    }
            elsif ( $forkId == ( $count++ % $numberForks ) ) {
	        my @properties;
	        if ( $csv->parse( $_ ) ) {
	            my @columns = $csv->fields();
		    my $columns_size = @columns;
		    # Check row has same number of columns as there were column headings:
		    if ( $columns_size != $numberColumns ) {
		        croak "Found \"$columns_size\" columns. There should have been \"$numberColumns\".\n".
		            "Row contents was: $_";
		    }
		    my $id = $columns[0];
		    for ( my $i = 1; $i < $numberColumns ; $i++ ) {
                        my $value = $column_headings[ $i ] . "=" . $columns[ $i ];
		        push ( @properties, $value );
		    }
                    $group->add( $id, \@properties );
		    Apache::Sling::Print::print_result( $group );
	        }
	        else {
	            croak "CSV broken, failed to parse line: " . $csv->error_input;
	        }
	    }
        }
        close ( $input ); 
    }
    return 1;
}
#}}}

#{{{sub delete
sub del {
    my ( $group, $actOnGroup ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::delete_setup( $group->{ 'BaseURL' }, $actOnGroup ) );
    my $success = Apache::Sling::GroupUtil::delete_eval( $res );
    my $message = "Group: \"$actOnGroup\" ";
    $message .= ( $success ? "deleted!" : "was not deleted!" );
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

#{{{sub check_exists
sub check_exists {
    my ( $group, $actOnGroup ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::exists_setup( $group->{ 'BaseURL' }, $actOnGroup ) );
    my $success = Apache::Sling::GroupUtil::exists_eval( $res );
    my $message = "Group \"$actOnGroup\" ";
    $message .= ( $success ? "exists!" : "does not exist!" );
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

#{{{sub member_add
sub member_add {
    my ( $group, $actOnGroup, $addMember ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::member_add_setup( $group->{ 'BaseURL' }, $actOnGroup, $addMember ) );
    my $success = Apache::Sling::GroupUtil::member_add_eval( $res );
    my $message = "Member: \"$addMember\" ";
    $message .= ( $success ? "added" : "was not added" );
    $message .= " to group \"$actOnGroup\"!";
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

#{{{sub member_add_from_file
sub member_add_from_file {
    my ( $group, $file, $forkId, $numberForks ) = @_;
    my $csv = Text::CSV->new();
    my $count = 0;
    my $numberColumns = 0;
    my @column_headings;
    if ( open my ($input), "<", $file ) {
        while ( <$input> ) {
            if ( $count++ == 0 ) {
	        # Parse file column headings first to determine field names:
	        if ( $csv->parse( $_ ) ) {
	            @column_headings = $csv->fields();
		    # First field must be group:
		    if ( $column_headings[0] !~ /^group$/ix ) {
		        croak "First CSV column must be the group ID, ".
		            "column heading must be \"group\". ".
		            "Found: \"" . $column_headings[0] . "\".\n";
		    }
		    # Second field must be user:
		    if ( $column_headings[1] !~ /^user$/ix ) {
		        croak "Second CSV column must be the user ID, ".
		            "column heading must be \"user\". ".
		            "Found: \"" . $column_headings[1] . "\".\n";
		    }
		    $numberColumns = @column_headings;
	        }
	        else {
	            croak "CSV broken, failed to parse line: " . $csv->error_input;
	        }
	    }
            elsif ( $forkId == ( $count++ % $numberForks ) ) {
	        if ( $csv->parse( $_ ) ) {
	            my @columns = $csv->fields();
		    my $columns_size = @columns;
		    # Check row has same number of columns as there were column headings:
		    if ( $columns_size != $numberColumns ) {
		        croak "Found \"$columns_size\" columns. There should have been \"$numberColumns\".\n".
		            "Row contents was: $_";
		    }
		    my $actOnGroup = $columns[0];
		    my $addMember = $columns[1];
                    $group->member_add( $actOnGroup, $addMember );
		    Apache::Sling::Print::print_result( $group );
	        }
	        else {
	            croak "CSV broken, failed to parse line: " . $csv->error_input;
	        }
	    }
        }
        close ( $input ); 
    }
    return 1;
}
#}}}

#{{{sub member_delete
sub member_delete {
    my ( $group, $actOnGroup, $deleteMember ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::member_delete_setup( $group->{ 'BaseURL' }, $actOnGroup, $deleteMember ) );
    my $success = Apache::Sling::GroupUtil::member_delete_eval( $res );
    my $message = "Member: \"$deleteMember\" ";
    $message .= ( $success ? "deleted" : "was not deleted" );
    $message .= " from group \"$actOnGroup\"!";
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

#{{{sub member_exists
sub member_exists {
    my ( $group, $actOnGroup, $existsMember ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::view_setup( $group->{ 'BaseURL' }, $actOnGroup ) );
    my $success = Apache::Sling::GroupUtil::view_eval( $res );
    my $message;
    if ( $success ) {
        my $group_info = from_json( $$res->content );
	my $is_member = 0;
        foreach my $member ( @{ $group_info->{ 'members' } } ) {
            if ( $member =~ /^$existsMember$/x ) {
	        $is_member = 1;
		last;
	    }
        }
	$success = $is_member;
	$message = "\"$existsMember\" is " . ( $is_member ? "" : "not " ) .
	    "a member of group \"$actOnGroup\"";
    }
    else {
        $message = "Problem viewing group: \"$actOnGroup\"";
    }
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

#{{{sub member_view
sub member_view {
    my ( $group, $actOnGroup ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::view_setup( $group->{ 'BaseURL' }, $actOnGroup ) );
    my $success = Apache::Sling::GroupUtil::view_eval( $res );
    my $message;
    if ( $success ) {
        my $group_info = from_json( $$res->content );
        my $number_members = @{ $group_info->{ 'members' } };
        my $members = "Group \"$actOnGroup\" has $number_members member(s):";
        foreach my $member ( @{ $group_info->{ 'members' } } ) {
            $members .= "\n$member";
        }
	$message = "$members";
	$success = $number_members;
    }
    else {
        $message = "Problem viewing group: \"$actOnGroup\"";
    }
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

#{{{sub view
sub view {
    my ( $group, $actOnGroup ) = @_;
    my $res = Apache::Sling::Request::request( \$group,
        Apache::Sling::GroupUtil::view_setup( $group->{ 'BaseURL' }, $actOnGroup ) );
    my $success = Apache::Sling::GroupUtil::view_eval( $res );
    my $message = ( $success ? $$res->content : "Problem viewing group: \"$actOnGroup\"" );
    $group->set_results( "$message", $res );
    return $success;
}
#}}}

1;
