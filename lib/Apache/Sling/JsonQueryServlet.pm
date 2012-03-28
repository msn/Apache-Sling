#!/usr/bin/perl -w

package Apache::Sling::JsonQueryServlet;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::JsonQueryServletUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.19';

#{{{sub new
sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $json_query_servlet = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $json_query_servlet, $class;
    return $json_query_servlet;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $json_query_servlet, $message, $response ) = @_;
    $json_query_servlet->{'Message'}  = $message;
    $json_query_servlet->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub all_nodes
sub all_nodes {
    my ($json_query_servlet) = @_;
    my $res = Apache::Sling::Request::request(
        \$json_query_servlet,
        Apache::Sling::JsonQueryServletUtil::all_nodes_setup(
            $json_query_servlet->{'BaseURL'}
        )
    );
    my $success = Apache::Sling::JsonQueryServletUtil::all_nodes_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem fetching all nodes"
    );
    $json_query_servlet->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::JsonQueryServlet - Query the JCR layer via the apache sling JSON query servlet.

=head1 ABSTRACT

query related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a JSON Query Servlet object

=head2 set_results

Set a suitable message and response for the json query object.

=head2 all_nodes

Return all nodes in the sling system in JSON format.

=head1 USAGE

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST JSON query servlet methods

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

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
