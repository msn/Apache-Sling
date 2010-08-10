#!/usr/bin/perl -w
package Apache::Sling;

use 5.008008;
use strict;
use warnings;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.11';


# Preloaded methods go here.

1;
__END__

=head1 NAME

Apache::Sling - Perl library for interacting with the apache sling web framework

=head1 SYNOPSIS

  use Apache::Sling;

=head1 DESCRIPTION

The Apache::Sling perl library is designed to provide a perl based interface on
to the Apache sling web framework. 

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://sling.apache.org

=head1 AUTHOR

D. D. Parry, E<lt>perl@ddp.me.ukE<gt>

=head1 VERSION

0.11

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: Daniel David Parry <perl@ddp.me.uk>
