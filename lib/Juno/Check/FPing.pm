use strict;
use warnings;
package Juno::Check::FPing;
# ABSTRACT: An FPing checker for Juno

use Carp;
use AnyEvent::Util 'fork_call';
use Any::Moose;
use namespace::autoclean;

with 'Juno::Role::Check';

has count => (
    is      => 'ro',
    isa     => 'Int',
    default => 3,
);

has cmd => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        return '/usr/sbin/fping -A -q -c ' . $self->count;
    },
);

sub check {
    my $self  = shift;
    my $cmd   = $self->cmd;
    my @hosts = @{ $self->hosts };

    foreach my $host (@hosts) {
        $self->has_on_before and $self->on_before( $self, $host );

        fork_call {
            chomp ( my $return = `$cmd $host 2>&1` );
            return $result;
        } sub {
            $self->has_on_result
                and $self->on_result->( $self, $host, $result );

            $self->analyze_ping_result( @_, $host )
        };
    }

    return 0;
}

sub analyze_ping_result {
    my $self   = shift;
    my $timing = shift;
    my $host   = shift;
    my $regex1 = qr{
        # 1.1.1.1 : xmt/rcv/%loss = 5/5/0%, min/avg/max = 235/379/602
        ^                                        # start
        ( \d+ \. \d+ \. \d+ \. \d+ )             # host ip
        \s+ : \s+                                # results separator
        xmt/rcv/%loss \s = \s \d+/\d+/(\d+)%, \s # loss percentage
        min/avg/max \s = \s
        \d+(?:\.\d+)?/(\d+(?:\.\d+)?)/\d+(?:\.\d+)? # average
        $                                           # finish
    }x;

    if ( ! defined $timing or $timing eq '' ) {
        $self->has_on_fail and $self->on_fail->( $self, $host );
        return;
    }

    if ( $timing =~ $regex1 ) {
        my ( $ip, $loss, $average ) = ( $1, $2, $3 );

        $host eq $ip
            or carp "Mismatched FPing result, host doesn't match IP\n";

        $self->has_on_success
            and $self->on_success->( $self, $host, $timing, $loss, $average );

        return;
    }

    $self->has_on_fail and $self->on_fail->( $self, $host, $timing );

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 hosts

An arrayref of hosts to check, overriding the default given to Juno.pm.

    my $juno = Juno->new(
        hosts  => [ 'Tom', 'Jerry' ],
        checks => {
            Ping => {
                hosts => [ 'Micky', 'Mini' ], # this overrides tom and jerry
            },
        },
    );

Now the Ping check will not check Tom and Jerry, but rather Micky and Mini.

This attribute derives from L<Juno::Role::Check>.

=head2 interval

An integer of seconds between each check (nor per-host).

This attribute derives from L<Juno::Role::Check>.

=head2 on_success

A coderef to run when making a successful request.

This attribute derives from L<Juno::Role::Check>.

=head2 on_fail

A coderef to run when making an unsuccessful request.

This attribute derives from L<Juno::Role::Check>.

=head2 on_result

A coderef to run when getting a response - any response. This is what you use
in case you want more control over what's going on.

This attribute derives from L<Juno::Role::Check>.

=head2 on_before

A coderef to run before making a request.

=head2 watcher

Holds the watcher for the Ping check timer.

This attribute derives from L<Juno::Role::Check>.

=head1 METHODS

=head2 check

L<Juno> will call this method for you. You should not call it yourself.

=head2 run

L<Juno> will call this method for you. You should not call it yourself.

