#!/usr/bin/perl

package Apache::Sling::ContentUtil;

use 5.008008;
use strict;
use warnings;
use Carp;
use Apache::Sling::URL;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.06';

=head1 NAME

ContentUtil - Utility library returning strings representing Rest queries that
perform content operations in the system.

=head1 ABSTRACT

ContentUtil perl library essentially provides the request strings needed to
interact with content functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=cut

#{{{sub add_setup

=pod

=head2 add_setup

Returns a textual representation of the request needed to add content to the
system.

=cut

sub add_setup {
    my ( $baseURL, $remoteDest, $properties ) = @_;
    croak "No base URL provided!" unless defined $baseURL;
    croak "No position or ID to perform action for specified!"
      unless defined $remoteDest;
    my $property_post_vars =
      Apache::Sling::URL::properties_array_to_string($properties);
    my $postVariables = "\$postVariables = [$property_post_vars]";
    return "post $baseURL/$remoteDest $postVariables";
}

#}}}

#{{{sub add_eval

=pod

=head2 add_eval

Check result of adding content.

=cut

sub add_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^20(0|1)$/x );
}

#}}}

#{{{sub copy_setup

=pod

=head2 copy_setup

Returns a textual representation of the request needed to copy content within
the system.

=cut

sub copy_setup {
    my ( $baseURL, $remoteSrc, $remoteDest, $replace ) = @_;
    croak "No base url defined!"                       unless defined $baseURL;
    croak "No content destination to copy to defined!" unless defined $remoteDest;
    croak "No content source to copy from defined!"    unless defined $remoteSrc;
    my $postVariables =
      "\$postVariables = [':dest','$remoteDest',':operation','copy'";
    $postVariables .= ( defined $replace ? ",':replace','true'" : "" );
    $postVariables .= "]";
    return "post $baseURL/$remoteSrc $postVariables";
}

#}}}

#{{{sub copy_eval

=pod

=head2 copy_eval

Inspects the result returned from issuing the request generated in copy_setup
returning true if the result indicates the content was copied successfully,
else false.

=cut

sub copy_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^20(0|1)$/x );
}

#}}}

#{{{sub delete_setup

=pod

=head2 delete_setup

Returns a textual representation of the request needed to delete content from
the system.

=cut

sub delete_setup {
    my ( $baseURL, $remoteDest ) = @_;
    croak "No base url defined!"                      unless defined $baseURL;
    croak "No content destination to delete defined!" unless defined $remoteDest;
    my $postVariables = "\$postVariables = [':operation','delete']";
    return "post $baseURL/$remoteDest $postVariables";
}

#}}}

#{{{sub delete_eval

=pod

=head2 delete_eval

Inspects the result returned from issuing the request generated in delete_setup
returning true if the result indicates the content was deleted successfully,
else false.

=cut

sub delete_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub exists_setup

=pod

=head2 exists_setup

Returns a textual representation of the request needed to test whether content
exists in the system.

=cut

sub exists_setup {
    my ( $baseURL, $remoteDest ) = @_;
    croak "No base url defined!" unless defined $baseURL;
    croak "No position or ID to perform exists for specified!"
      unless defined $remoteDest;
    return "get $baseURL/$remoteDest.json";
}

#}}}

#{{{sub exists_eval

=pod

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the content does exist in the system,
else false.

=cut

sub exists_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub move_setup

=pod

=head2 move_setup

Returns a textual representation of the request needed to move content within
the system.

=cut

sub move_setup {
    my ( $baseURL, $remoteSrc, $remoteDest, $replace ) = @_;
    croak "No base url defined!"                       unless defined $baseURL;
    croak "No content destination to move to defined!" unless defined $remoteDest;
    croak "No content source to move from defined!"    unless defined $remoteSrc;
    my $postVariables =
      "\$postVariables = [':dest','$remoteDest',':operation','move'";
    $postVariables .= ( defined $replace ? ",':replace','true'" : "" );
    $postVariables .= "]";
    return "post $baseURL/$remoteSrc $postVariables";
}

#}}}

#{{{sub move_eval

=pod

=head2 move_eval

Inspects the result returned from issuing the request generated in move_setup
returning true if the result indicates the content was moved successfully,
else false.

=cut

sub move_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^20(0|1)$/x );
}

#}}}

#{{{sub upload_file_setup

=pod

=head2 upload_file_setup

Returns a textual representation of the request needed to upload a file to the system.

=cut

sub upload_file_setup {
    my ( $baseURL, $localPath, $remoteDest, $filename ) = @_;
    croak "No base URL provided to upload against!" unless defined $baseURL;
    croak "No local file to upload defined!"        unless defined $localPath;
    croak "No remote path to upload to defined for file $localPath!"
      unless defined $remoteDest;
    $filename = "./*" if ( $filename =~ /^$/x );
    my $postVariables = "\$postVariables = []";
    return
      "fileupload $baseURL/$remoteDest $filename $localPath $postVariables";
}

#}}}

#{{{sub upload_file_eval

=pod

=head2 upload_file_eval

Check result of system upload_file.

=cut

sub upload_file_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^20(0|1)$/x );
}

#}}}

1;
