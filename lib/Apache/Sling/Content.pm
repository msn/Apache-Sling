#!/usr/bin/perl

package Apache::Sling::Content;

use 5.008008;
use strict;
use warnings;
use Carp;
use Apache::Sling::ContentUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.06';

=head1 NAME

Content - content related functionality for Sling implemented over rest
APIs.

=head1 ABSTRACT

Perl library providing a layer of abstraction to the REST content methods

=head2 Methods

=cut

#{{{sub new

=pod

=head2 new

Create, set up, and return a Content object.

=cut

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    croak "no authn provided!" unless defined $authn;
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
sub set_results {
    my ( $content, $message, $response ) = @_;
    $content->{'Message'}  = $message;
    $content->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $content, $remoteDest, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::add_setup(
            $content->{'BaseURL'}, $remoteDest, $properties
        )
    );
    my $success = Apache::Sling::ContentUtil::add_eval($res);
    my $message = "Content addition to \"$remoteDest\" ";
    $message .= ( $success ? "succeeded!" : "failed!" );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub copy
sub copy {
    my ( $content, $remoteSrc, $remoteDest, $replace ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::copy_setup(
            $content->{'BaseURL'}, $remoteSrc, $remoteDest, $replace
        )
    );
    my $success = Apache::Sling::ContentUtil::copy_eval($res);
    my $message = "Content copy from \"$remoteSrc\" to \"$remoteDest\" ";
    $message .= ( $success ? "completed!" : "did not complete successfully!" );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub del
sub del {
    my ( $content, $remoteDest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::delete_setup(
            $content->{'BaseURL'}, $remoteDest
        )
    );
    my $success = Apache::Sling::ContentUtil::delete_eval($res);
    my $message = "Content \"$remoteDest\" ";
    $message .= ( $success ? "deleted!" : "was not deleted!" );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $content, $remoteDest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::exists_setup(
            $content->{'BaseURL'}, $remoteDest
        )
    );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = "Content \"$remoteDest\" ";
    $message .= ( $success ? "exists!" : "does not exist!" );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub move
sub move {
    my ( $content, $remoteSrc, $remoteDest, $replace ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::move_setup(
            $content->{'BaseURL'}, $remoteSrc, $remoteDest, $replace
        )
    );
    my $success = Apache::Sling::ContentUtil::move_eval($res);
    my $message = "Content move from \"$remoteSrc\" to \"$remoteDest\" ";
    $message .= ( $success ? "completed!" : "did not complete successfully!" );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub upload_file
sub upload_file {
    my ( $content, $localPath, $remotePath, $filename ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::upload_file_setup(
            $content->{'BaseURL'}, $localPath, $remotePath, $filename
        )
    );
    my $success  = Apache::Sling::ContentUtil::upload_file_eval($res);
    my $basename = $localPath;
    $basename =~ s/^(.*\/)([^\/]*)$/$2/x;
    my $remoteDest =
      $remotePath . ( $filename !~ /^$/x ? "/$filename" : "/$basename" );
    my $message = "Content: \"$localPath\" upload to \"$remoteDest\" ";
    $message .= ( $success ? "succeeded!" : "failed!" );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub upload_from_file
sub upload_from_file {
    my ( $content, $file, $forkId, $numberForks ) = @_;
    my $count = 0;
    if ( open my ($input), "<", $file ) {
        while (<$input>) {
            if ( $forkId == ( $count++ % $numberForks ) ) {
                chomp;
                $_ =~ /^(.*?),(.*?)$/x or croak "Problem parsing content to add";
                my $localPath  = $1;
                my $remotePath = $2;
                if ( defined $localPath && defined $remotePath ) {
                    $content->upload_file( $localPath, $remotePath, "" );
                    Apache::Sling::Print::print_result($content);
                }
                else {
                    print "ERROR: Problem parsing content to add: \"$_\"\n";
                }
            }
        }
        close($input);
    }
    else {
        croak "Problem opening file: $file";
    }
    return 1;
}

#}}}

#{{{sub view
sub view {
    my ( $content, $remoteDest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::exists_setup(
            $content->{'BaseURL'}, $remoteDest
        )
    );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = (
          $success
        ? $$res->content
        : "Problem viewing content: \"$remoteDest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub view_file
sub view_file {
    my ( $content, $remoteDest ) = @_;
    my $res = Apache::Sling::Request::request( \$content,
        "get $content->{ 'BaseURL' }/$remoteDest" );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing content: \"$remoteDest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

1;
