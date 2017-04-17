package App::CISetup::Role::ConfigFile;

use App::CISetup::Wrapper::OurMoose::Role;

use File::pushd;
use IPC::Run3 qw( run3 );
use List::AllUtils qw( first_index uniq );
use App::CISetup::Types qw( Bool PathClassFile );
use Path::Class::Rule;
use Try::Tiny;
use YAML qw( Dump LoadFile );

requires qw(
    _update_config
    _fix_up_yaml
);

has file => (
    is       => 'ro',
    isa      => PathClassFile,
    required => 1,
);

sub update_file ($self) {
    my $file = $self->file;
    my $orig = $file->slurp;

    my $err;
    my $content = try {
        LoadFile($file);
    }
    catch {
        $err = "YAML parsing error: $_\n";
    };

    return unless $content || $err;

    if ($err) {
        print "\n\n\n", $file, "\n";
        print $err;
        return;
    }

    $self->_update_config($content);

    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    no warnings 'once';

    # If Perl versions aren't quotes then Travis display 5.10 as "5.1"

    ## no critic (Variables::ProhibitPackageVars)
    local $YAML::QuoteNumericStrings = 1;
    my $yaml = Dump($content);

    $yaml = $self->_fix_up_yaml($yaml);

    return if $yaml eq $orig;

    say "Updated $file";

    $file->spew($yaml);

    return;
}

sub _reorder_yaml_blocks ( $self, $yaml, $blocks_order ) {
    my $re = qr/^
                (
                    ([a-z_]+): # key:
                    (?:
                        (?:$)\n.+?
                    |
                        \ .+?\n
                    )
                )
                (?=^[a-z]|\z)
               /xms;

    my %blocks;
    while ( $yaml =~ /$re/g ) {
        $blocks{$2} = $1;
    }

    for my $name ( keys %blocks ) {
        my $method = '_reorder_' . $name . '_block';
        next unless $self->can($method);
        $blocks{$name} = $self->$method( $blocks{$name} );
    }

    my %known_blocks = map { $_ => 1 } $blocks_order->@*;
    for my $block ( keys %blocks ) {
        die "Unknown block $block in " . $self->file
            unless $known_blocks{$block};
    }

    return "---\n" . join q{}, map { $blocks{$_} // () } $blocks_order->@*;
}

1;
