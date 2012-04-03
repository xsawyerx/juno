use strict;
use warnings;
package Juno;
# ABSTRACT: Asynchronous event-driven checking mechanism

use Class::Load 'load_class';
use Any::Moose;
use namespace::autoclean;

has checks => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    required => 1,
);

has hosts => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has interval => (
    is      => 'ro',
    isa     => 'Int',
    default => 10,
);

sub run {
    my $self   = shift;
    my %checks = %{ $self->checks };

    foreach my $check ( keys %checks ) {
        my $class = "Juno::Check::$check";

        load_class($class);

        my $checker = $class->new( %{ $checks{$check} } );

        $checker->run();
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

This runs an asynchronous checker on two servers (I<jack> and I<jill>), running
an HTTP test every 10 seconds with an additional I<Host> header.

    my $juno = Juno->new(
        hosts    => [ 'jack', 'jill' ],
        interval => 10,
        checks   => {
            HTTP => {
                headers => {
                    [ 'Host', 'example.com' ],
                },

                on_result => sub {
                    my $result = shift;
                    ...
                },
            },
        },
    );

    # makes juno run in the background
    $juno->run;

=head1 DESCRIPTION

Juno is a hub of checking methods (HTTP, Ping, SNMP, etc.) meant to provide
developers with an asynchronous event-based checking agent that returns
results you can then use as probed data.

This helps you write stuff like monitoring services.

=head1 ATTRIBUTES

=head2 checks

The checks you want to run.

This is a hashref of the checks. The key is the check itself (correlates to the
class in C<Juno::Check::>) and the values are the attributes to that check.

=head2 hosts

An arrayref hosts you want all checks to monitor.

=head2 interval

The interval for every check.

=head1 METHODS

=head2 run

Run Juno.

