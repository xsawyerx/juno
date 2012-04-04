use strict;
use warnings;
package Juno;
# ABSTRACT: Asynchronous event-driven checking mechanism

use Class::Load 'load_class';
use Any::Moose;
use namespace::autoclean;

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

has prop_attributes => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [
        qw/hosts interval/
    ] },
);

has checks => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    required => 1,
);

has check_objects => (
    is      => 'ro',
    isa     => 'ArrayRef',
    builder => '_build_check_objects',
);

sub _build_check_objects {
    my $self   = shift;
    my %checks = %{ $self->checks };
    my @checks = ();

    foreach my $check ( keys %checks ) {
        my $class = "Juno::Check::$check";
        load_class($class);

        my %check_data = %{ $checks{$check} };

        foreach my $prop_key ( @{ $self->prop_attributes } ) {
            exists $check_data{$prop_key}
                or $check_data{$prop_key} = $self->$prop_key;
        }

        push @checks, $class->new(%check_data);
    }

    return \@checks;
}

sub run {
    my $self = shift;

    foreach my $check ( @{ $self->check_objects } ) {
        $check->run();
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

=head2 hosts

An arrayref of hosts you want all checks to monitor.

=head2 interval

The interval for every check.

Default: 10 seconds.

=head2 checks

The checks you want to run.

This is a hashref of the checks. The key is the check itself (correlates to the
class in C<Juno::Check::>) and the values are the attributes to that check.

=head2 prop_attributes

An arrayref of attributes that should be propagated from the main object to
the checks.

Default: hosts, interval.

=head1 METHODS

=head2 run

Run Juno.

