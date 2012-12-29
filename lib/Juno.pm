use strict;
use warnings;
package Juno;
# ABSTRACT: Asynchronous event-driven checking mechanism

use Moo;
use MooX::Types::MooseLike::Base qw<Str Num ArrayRef HashRef>;
use Sub::Quote;
use Class::Load 'load_class';
use namespace::autoclean;

with 'MooseX::Role::Loggable';

has hosts => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [] },
);

has interval => (
    is      => 'ro',
    isa     => Num,
    default => sub {10},
);

has after => (
    is      => 'ro',
    isa     => Num,
    default => sub {0},
);

has prop_attributes => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub { [ qw<hosts interval after> ] },
);

has checks => (
    is       => 'ro',
    isa      => HashRef[HashRef],
    required => 1,
);

has check_objects => (
    is  => 'lazy',
    isa => ArrayRef,
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

        push @checks, $class->new(
            %check_data,
            logger => $self->logger,
        );
    }

    return \@checks;
}

sub run {
    my $self = shift;

    foreach my $check ( @{ $self->check_objects } ) {
        $self->log( 'Running', ref $check );
        $check->run();
    }
}

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
                    { 'Host', 'example.com' },
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

    my $juno = Juno->new(
        hosts  => [ '10.0.0.2', '10.0.0.3' ],
        checks => {
            HTTP => {
                path => '/test',
            },
        },
    );

The C<checks> argument is the most important one, and it is mandatory. This
defines what will be checked, and adds additional parameters. Some might be
optional, some might be mandatory. You should read each check's documentation
to know what options are available and which are required.

If you need to run multiple checks of the same type, such as two different
HTTP tests, you will need to run two Juno instances. It's perfectly fine,
because Juno has no global variables and works seamlessly with multiple
instances.

Hopefully this will change in the future, providing more advanced options to
have multiple checks of the same type.

=head2 hosts

An arrayref of hosts you want all checks to monitor.

    my $juno = Juno->new(
        hosts => [ '10.0.1.100', 'sub.domain.com' ],
        ...
    );

=head2 interval

The interval for every check.

    my $juno = Juno->new(
        interval => 5.6,
        ...
    );

This sets every check to be run every 5.6 seconds.

Default: 10 seconds.

=head2 after

Delay seconds for first check.

    my $juno = Juno->new(
        after => 10,
        ...
    );

This will force all checks to only begin after 10 seconds. It will basically
rest for 10 seconds and then start the checks. We can't really think of many
reasons why you would need this (perhaps waiting for a database connection?),
but nonetheless it is an optional feature and you should have control over it
if you want to change it.

If this is set to zero (the default), it will not delay the execution of the
checks.

Default: 0 seconds

=head2 prop_attributes

The C<prop_attributes> are an arrayref of attributes that are propagated from
the main Juno object to each check object. This could be a hard-coded list, but
it's cleaner to put it in an attribute. This means it's available for you to
change. There really is no need for you to do that.

    my $juno = Juno->new(
        prop_attributes => [ 'hosts', 'interval' ],
        ...
    );

Default: hosts, interval, after.

=head1 METHODS

=head2 run

Run Juno.

    use Juno;
    use AnyEvent;

    my $cv   = AnyEvent->condvar;
    my $juno = Juno->new(...);

    $juno->run;
    $cv->recv;

When you call Juno's C<run> method, it will begin running the checks.
Separating the running to a method allows you to set up a Juno object (or
several Juno objects) in advance and calling them later on when you're ready
for them to start working.

However, note that running Juno will not keep the program running by itself.
You will need some condition to keep the program running, as demonstrated
above.

