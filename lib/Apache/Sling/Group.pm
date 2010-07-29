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

our $VERSION = '0.09';

#{{{sub new

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $group = {
        BaseURL  => $$authn->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $group, $class;
    return $group;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $group, $message, $response ) = @_;
    $group->{'Message'}  = $message;
    $group->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $group, $act_on_group, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::add_setup(
            $group->{'BaseURL'}, $act_on_group, $properties
        )
    );
    my $success = Apache::Sling::GroupUtil::add_eval($res);
    my $message = "Group: \"$act_on_group\" ";
    $message .= ( $success ? 'added!' : 'was not added!' );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub add_from_file
sub add_from_file {
    my ( $group, $file, $fork_id, $number_of_forks ) = @_;
    my $csv               = Text::CSV->new();
    my $count             = 0;
    my $number_of_columns = 0;
    my @column_headings;
    if ( open my ($input), '<', $file ) {
        while (<$input>) {
            if ( $count++ == 0 ) {

                # Parse file column headings first to determine field names:
                if ( $csv->parse($_) ) {
                    @column_headings = $csv->fields();

                    # First field must be group:
                    if ( $column_headings[0] !~ /^[Gg][Rr][Oo][Uu][Pp]$/msx ) {
                        croak 'First CSV column must be the group ID, '
                          . 'column heading must be "group". '
                          . 'Found: "'
                          . $column_headings[0] . "\".\n";
                    }
                    $number_of_columns = @column_headings;
                }
                else {
                    croak 'CSV broken, failed to parse line: '
                      . $csv->error_input;
                }
            }
            elsif ( $fork_id == ( $count++ % $number_of_forks ) ) {
                my @properties;
                if ( $csv->parse($_) ) {
                    my @columns      = $csv->fields();
                    my $columns_size = @columns;

           # Check row has same number of columns as there were column headings:
                    if ( $columns_size != $number_of_columns ) {
                        croak
"Found \"$columns_size\" columns. There should have been \"$number_of_columns\".\n"
                          . "Row contents was: $_";
                    }
                    my $id = $columns[0];
                    for ( my $i = 1 ; $i < $number_of_columns ; $i++ ) {
                        my $heading = $column_headings[$i];
                        my $data    = $columns[$i];
                        my $value   = "$heading = $data";
                        push @properties, $value;
                    }
                    $group->add( $id, \@properties );
                    Apache::Sling::Print::print_result($group);
                }
                else {
                    croak 'CSV broken, failed to parse line: '
                      . $csv->error_input;
                }
            }
        }
        close $input or croak q{Problem closing input!};
    }
    return 1;
}

#}}}

#{{{sub delete
sub del {
    my ( $group, $act_on_group ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::delete_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::delete_eval($res);
    my $message = "Group: \"$act_on_group\" ";
    $message .= ( $success ? 'deleted!' : 'was not deleted!' );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $group, $act_on_group ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::exists_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::exists_eval($res);
    my $message = "Group \"$act_on_group\" ";
    $message .= ( $success ? 'exists!' : 'does not exist!' );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub member_add
sub member_add {
    my ( $group, $act_on_group, $add_member ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::member_add_setup(
            $group->{'BaseURL'}, $act_on_group, $add_member
        )
    );
    my $success = Apache::Sling::GroupUtil::member_add_eval($res);
    my $message = "Member: \"$add_member\" ";
    $message .= ( $success ? 'added' : 'was not added' );
    $message .= " to group \"$act_on_group\"!";
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub member_add_from_file
sub member_add_from_file {
    my ( $group, $file, $fork_id, $number_of_forks ) = @_;
    my $csv               = Text::CSV->new();
    my $count             = 0;
    my $number_of_columns = 0;
    my @column_headings;
    if ( open my ($input), '<', $file ) {
        while (<$input>) {
            if ( $count++ == 0 ) {

                # Parse file column headings first to determine field names:
                if ( $csv->parse($_) ) {
                    @column_headings = $csv->fields();

                    # First field must be group:
                    if ( $column_headings[0] !~ /^[Gg][Rr][Oo][Uu][Pp]$/msx ) {
                        croak 'First CSV column must be the group ID, '
                          . 'column heading must be "group". '
                          . 'Found: "'
                          . $column_headings[0] . "\".\n";
                    }

                    # Second field must be user:
                    if ( $column_headings[1] !~ /^[Uu][Ss][Ee][Rr]$/msx ) {
                        croak 'Second CSV column must be the user ID, '
                          . 'column heading must be "user". '
                          . 'Found: "'
                          . $column_headings[1] . "\".\n";
                    }
                    $number_of_columns = @column_headings;
                }
                else {
                    croak 'CSV broken, failed to parse line: '
                      . $csv->error_input;
                }
            }
            elsif ( $fork_id == ( $count++ % $number_of_forks ) ) {
                if ( $csv->parse($_) ) {
                    my @columns      = $csv->fields();
                    my $columns_size = @columns;

           # Check row has same number of columns as there were column headings:
                    if ( $columns_size != $number_of_columns ) {
                        croak
"Found \"$columns_size\" columns. There should have been \"$number_of_columns\".\n"
                          . "Row contents was: $_";
                    }
                    my $act_on_group = $columns[0];
                    my $add_member   = $columns[1];
                    $group->member_add( $act_on_group, $add_member );
                    Apache::Sling::Print::print_result($group);
                }
                else {
                    croak 'CSV broken, failed to parse line: '
                      . $csv->error_input;
                }
            }
        }
        close $input or croak q{Problem closing input!};
    }
    return 1;
}

#}}}

#{{{sub member_delete
sub member_delete {
    my ( $group, $act_on_group, $delete_member ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::member_delete_setup(
            $group->{'BaseURL'}, $act_on_group, $delete_member
        )
    );
    my $success = Apache::Sling::GroupUtil::member_delete_eval($res);
    my $message = "Member: \"$delete_member\" ";
    $message .= ( $success ? 'deleted' : 'was not deleted' );
    $message .= " from group \"$act_on_group\"!";
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub member_exists
sub member_exists {
    my ( $group, $act_on_group, $exists_member ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::view_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::view_eval($res);
    my $message;
    if ($success) {
        my $group_info = from_json( ${ $res->content } );
        my $is_member  = 0;
        foreach my $member ( @{ $group_info->{'members'} } ) {
            if ( $member eq "$exists_member" ) {
                $is_member = 1;
                last;
            }
        }
        $success = $is_member;
        $message =
            "\"$exists_member\" is "
          . ( $is_member ? q{} : 'not ' )
          . "a member of group \"$act_on_group\"";
    }
    else {
        $message = "Problem viewing group: \"$act_on_group\"";
    }
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub member_view
sub member_view {
    my ( $group, $act_on_group ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::view_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::view_eval($res);
    my $message;
    if ($success) {
        my $group_info     = from_json( ${ $res->content } );
        my $number_members = @{ $group_info->{'members'} };
        my $members = "Group \"$act_on_group\" has $number_members member(s):";
        foreach my $member ( @{ $group_info->{'members'} } ) {
            $members .= "\n$member";
        }
        $message = "$members";
        $success = $number_members;
    }
    else {
        $message = "Problem viewing group: \"$act_on_group\"";
    }
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub view
sub view {
    my ( $group, $act_on_group ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Apache::Sling::GroupUtil::view_setup(
            $group->{'BaseURL'}, $act_on_group
        )
    );
    my $success = Apache::Sling::GroupUtil::view_eval($res);
    my $message = (
        $success
        ? ${ $res->content }
        : "Problem viewing group: \"$act_on_group\""
    );
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Group

=head1 ABSTRACT

group related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a Group Object.

=head1 USAGE

use Apache::Sling::Group;

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST group methods

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

COPYRIGHT: (c) 2010 Daniel David Parry <perl@ddp.me.uk>
