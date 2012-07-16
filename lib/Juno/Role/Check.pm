use strict;
use warnings;
package Juno::Role::Check;
# ABSTRACT: Check role for Juno

use AnyEvent;
use Any::Moose 'Role';
use namespace::autoclean;

with 'MooseX::Role::Loggable';

has hosts => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has interval => (
    is      => 'ro',
    isa     => 'Num',
    default => 10,
);

has on_before => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_on_before',
);

has on_success => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_on_success',
);

has on_fail => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_on_fail',
);

has on_result => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_on_result',
);

has watcher => (
    is      => 'ro',
    writer  => 'set_watcher',
    clearer => 'clear_watcher',
);

requires 'check';

sub run {
    my $self = shift;

    # keep a watcher per check
    $self->set_watcher( AnyEvent->timer(
        interval => $self->interval,
        cb       => sub {
            $self->check;
        },
    ) );

    return 1;
}

1;

__END__

=head1 DESCRIPTION

This role provides Juno checks with basic functionality they all share.

=head1 ATTRIBUTES

=head2 hosts

Custom per-check hosts list.

=head2 interval

Custom per-check interval.

=head2 on_before

A callback for before an action occurs.

=head2 on_success

A callback for when an action succeeded.

=head2 on_fail

A callback for when an action failed.

=head2 on_result

A callback to catch any result.

This is useful if you have your own logic and don't count on the check to
decide if something is successful or not.

Suppose you run the HTTP check and you have a special setup where 403 Forbidden
is actually a correct result.

