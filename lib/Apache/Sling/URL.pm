#!/usr/bin/perl

package Apache::Sling::URL;

use 5.008008;
use strict;
use warnings;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.05';

=head1 NAME

URL - useful utility functions for manipulating URLs.

=head1 ABSTRACT

Utility library providing useful URL functions for general Rest functionality.

=cut

#{{{sub add_leading_slash

=pod

=head2 add_leading_slash

Function to add a leading slash to a string if one does not exist.

=cut

sub add_leading_slash {
    my ($value) = @_;
    if ( defined $value ) {
        if ( $value !~ /^\//x ) {
            $value = "/$value";
        }
    }
    return ($value);
}

#}}}

#{{{sub strip_leading_slash

=pod

=head2 strip_leading_slash

Function to remove any leading slashes from a string.

=cut

sub strip_leading_slash {
    my ($value) = @_;
    if ( defined $value ) {
        $value =~ s/^\///x;
    }
    return ($value);
}

#}}}

#{{{sub properties_array_to_string

=pod

=head2 properties_array_to_string

Function to convert an array of a property values to a suitable string
representation.

=cut

sub properties_array_to_string {
    my ($properties) = @_;
    my $property_post_vars;
    foreach my $property ( @{$properties} ) {
        # Escaping single quotes:
        $property =~ s/'/\\'/g;
        $property =~ /^([^=]*)=(.*)/x;
        if ( defined $1 && defined $2 ) {
            $property_post_vars .= "'$1','$2',";
        }
    }
    if (defined $property_post_vars) {
        $property_post_vars =~ s/,$//x;
    }
    return $property_post_vars;
}

#}}}

#{{{sub urlencode

=pod

=head2 urlencode

Function to encode a string so it is suitable for use in urls.

=cut

sub urlencode {
    my ($value) = @_;
    $value =~ s/([^a-zA-Z_0-9 ])/"%" . uc(sprintf "%lx" , unpack("C", $1))/egx;
    $value =~ tr/ /+/;
    return ($value);
}

#}}}

#{{{sub url_input_sanitize

=pod

=head2 url_input_sanitize

Sanitizes input url by removing trailing slashes and adding a protocol if
missing.

=cut

sub url_input_sanitize {
    my ($url) = @_;
    $url = ( defined $url ? $url : "http://localhost:8080" );
    $url = ( $url !~ /^$/x ? $url : "http://localhost:8080" );
    $url =~ s/(.*)\/$/$1/x;
    $url = ( $url !~ /^http/x ? "http://$url" : "$url" );
    return ($url);
}

#}}}

1;
