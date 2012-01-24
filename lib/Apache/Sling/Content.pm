#!/usr/bin/perl -w

package Apache::Sling::Content;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::ContentUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.17';

#{{{sub new
sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $content = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $content, $class;
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
    my ( $content, $remote_dest, $properties ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::add_setup(
            $content->{'BaseURL'}, $remote_dest, $properties
        )
    );
    my $success = Apache::Sling::ContentUtil::add_eval($res);
    my $message = "Content addition to \"$remote_dest\" ";
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub copy
sub copy {
    my ( $content, $remote_src, $remote_dest, $replace ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::copy_setup(
            $content->{'BaseURL'}, $remote_src, $remote_dest, $replace
        )
    );
    my $success = Apache::Sling::ContentUtil::copy_eval($res);
    my $message = "Content copy from \"$remote_src\" to \"$remote_dest\" ";
    $message .= ( $success ? 'completed!' : 'did not complete successfully!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub del
sub del {
    my ( $content, $remote_dest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::delete_setup(
            $content->{'BaseURL'}, $remote_dest
        )
    );
    my $success = Apache::Sling::ContentUtil::delete_eval($res);
    my $message = "Content \"$remote_dest\" ";
    $message .= ( $success ? 'deleted!' : 'was not deleted!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub check_exists
sub check_exists {
    my ( $content, $remote_dest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::exists_setup(
            $content->{'BaseURL'}, $remote_dest
        )
    );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = "Content \"$remote_dest\" ";
    $message .= ( $success ? 'exists!' : 'does not exist!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub move
sub move {
    my ( $content, $remote_src, $remote_dest, $replace ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::move_setup(
            $content->{'BaseURL'}, $remote_src, $remote_dest, $replace
        )
    );
    my $success = Apache::Sling::ContentUtil::move_eval($res);
    my $message = "Content move from \"$remote_src\" to \"$remote_dest\" ";
    $message .= ( $success ? 'completed!' : 'did not complete successfully!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub upload_file
sub upload_file {
    my ( $content, $local_path, $remote_path, $filename ) = @_;
    $filename = defined $filename ? $filename : q{};
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::upload_file_setup(
            $content->{'BaseURL'}, $local_path, $remote_path, $filename
        )
    );
    my $success  = Apache::Sling::ContentUtil::upload_file_eval($res);
    my $basename = $local_path;
    $basename =~ s/^(.*\/)([^\/]*)$/$2/msx;
    my $remote_dest =
      $remote_path . ( $filename ne q{} ? "/$filename" : "/$basename" );
    my $message = "Content: \"$local_path\" upload to \"$remote_dest\" ";
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub upload_from_file
sub upload_from_file {
    my ( $content, $file, $fork_id, $number_of_forks ) = @_;
    my $count = 0;
    if ( defined $file && open my ($input), '<', $file ) {
        while (<$input>) {
            if ( $fork_id == ( $count++ % $number_of_forks ) ) {
                chomp;
                $_ =~ /^(.*?),(.*?)$/msx
                  or croak 'Problem parsing content to add';
                if ( defined $1 && defined $2 ) {
                    my $local_path  = $1;
                    my $remote_path = $2;
                    $content->upload_file( $local_path, $remote_path, q{} );
                    Apache::Sling::Print::print_result($content);
                }
                else {
                    print "ERROR: Problem parsing content to add: \"$_\"\n"
                      or croak 'Problem printing!';
                }
            }
        }
        close $input or croak 'Problem closing input!';
    }
    else {
        $file = ( defined $file ? $file : '' );
        croak "Problem opening file: '$file'";
    }
    return 1;
}

#}}}

#{{{sub view
sub view {
    my ( $content, $remote_dest ) = @_;
    my $res = Apache::Sling::Request::request(
        \$content,
        Apache::Sling::ContentUtil::exists_setup(
            $content->{'BaseURL'}, $remote_dest
        )
    );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing content: \"$remote_dest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub view_file
sub view_file {
    my ( $content, $remote_dest ) = @_;
    if ( !defined $remote_dest ) {
        croak 'No file to view specified!';
    }
    my $res = Apache::Sling::Request::request( \$content,
        "get $content->{ 'BaseURL' }/$remote_dest" );
    my $success = Apache::Sling::ContentUtil::exists_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : "Problem viewing content: \"$remote_dest\""
    );
    $content->set_results( "$message", $res );
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::Content - Manipulate Content in an Apache SLing instance.

=head1 ABSTRACT

content related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a Content object.

=head2 set_results

Set a suitable message and response for the content object.

=head2 add

Add new content to the system.

=head2 copy

Copy content in the system.

=head2 check_exists

Check whether content exists.

=head2 del

Delete content.

=head2 move

Move location of content in the system.

=head2 upload_file

Upload a file into the system.

=head2 upload_from_file

Upload new content to the system based on definitions in a file.

=head2 view

View content details.

=head2 view_file

View content.

=head1 USAGE

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST content methods

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
