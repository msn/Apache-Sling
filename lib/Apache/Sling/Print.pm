#!/usr/bin/perl

package Apache::Sling::Print;

use 5.008008;
use strict;
use warnings;
use Carp;
use Fcntl ':flock';
use File::Temp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.07';

=head1 NAME

Print - useful utility functions for general print to screeen and print to file
functionality.

=head1 ABSTRACT

Utility library providing useful utility functions for general Print
functionality.

=cut

#{{{sub print_with_lock

=pod

=head2 print_with_lock

Selects printing to standard out or to log with locking based on whether a suitable log file is defined.

=cut

sub print_with_lock {
    my ( $message, $file ) = @_;
    if ( defined $file ) {
        return print_file_lock( "$message", $file );
    }
    else {
        return print_lock("$message");
    }
}

#}}}

#{{{sub print_file_lock

=pod

=head2 print_file_lock

Prints out a specified message to a specified file with locking in an attempt
to prevent competing threads or forks from stepping on each others toes when
writing to the file.

=cut

sub print_file_lock {
    my ( $message, $file ) = @_;
    if ( open my $out, ">>", $file ) {
        flock( $out, LOCK_EX );
        print $out $message . "\n";
        flock( $out, LOCK_UN );
        close($out);
    }
    else {
        croak "Could not open file: $file";
    }
    return 1;
}

#}}}

#{{{sub print_lock

=pod

=head2 print_lock

Prints out a specified message with locking in an attempt to prevent competing
threads or forks from stepping on each others toes when printing to stdout.

=cut

sub print_lock {
    my ($message) = @_;
    my ( $tmp_print_file_handle, $tmp_print_file_name ) = File::Temp::tempfile();
    if ( open my $lock, ">>", $tmp_print_file_name ) {
        flock( $lock, LOCK_EX );
        print $message . "\n";
        flock( $lock, LOCK_UN );
        close($lock);
        unlink($tmp_print_file_name);
    }
    else {
        croak q(Could not open lock on temporary file!);
    }
    return 1;
}

#}}}

#{{{sub print_result

=pod

=head2 print_result

Takes an object (user, group, site, etc) and prints out it's Message value,
appending a new line. Also looks at the verbosity level and if greater than or
equal to 1 will print extra information extracted from the object's Response
object. At the moment, won't print if log is defined, as the prints to log
happen elsewhere. TODO tidy that up.

=cut

sub print_result {
    my ($object) = @_;
    my $message = $object->{'Message'};
    if ( $object->{'Verbose'} >= 1 ) {
        $message .= "\n**** Status line was: ";
        $message .= ${ $object->{'Response'} }->status_line;
        if ( $object->{'Verbose'} >= 3 ) {
            $message .= "\n**** Full Content of Response was: \n";
            $message .= ${ $object->{'Response'} }->content;
        }
    }
    print_with_lock( $message, $object->{'Log'} );
    return 1;
}

#}}}

#{{{sub dateTime

=pod

=head2 dateTime

Returns a current date time string, which is useful for log timestamps.

=cut

sub dateTime {
    my @months   = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    (
        my $sec,
        my $minute,
        my $hour,
        my $dayOfMonth,
        my $month,
        my $yearOffset,
        my $dayOfWeek,
        my $dayOfYear,
        my $daylightSavings
    ) = localtime();
    $sec = "0$sec" if $sec < 10;
    $sec = "0$minute" if $minute < 10;
    my $year = 1900 + $yearOffset;
    return
      "$weekDays[$dayOfWeek] $months[$month] $dayOfMonth $hour:$minute:$sec";
}

#}}}

1;
