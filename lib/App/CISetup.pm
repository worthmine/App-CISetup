package App::CISetup;

use v5.14;
use strict;
use warnings;

# For use autodie qw( :all ) elsewhere
use IPC::System::Simple ();

our $VERSION = '0.19';

1;

# ABSTRACT: Command line tools to generate and update Travis and AppVeyor configs for Perl libraries

__END__

=pod

=head1 DESCRIPTION

This distro includes two command-line tools, L<setup-travis-yml.pl> and
L<setup-appveyor-yml.pl>. They update Travis and AppVeyor YAML config files
with some opinionated defaults. See the docs for the respective scripts for
more details.

