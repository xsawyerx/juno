use strict;
use warnings;
package Juno::Check::TCP;
# ABSTRACT: A TCP check for Juno

use Moo;
use MooX::Types::MooseLike::Base qw<Int>;
use AnyEvent::Socket;
use namespace::autoclean;

with 'Juno::Role::Check';

has port => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

sub check {
    my $self  = shift;
    my @hosts = @{ $self->hosts };
    my $port  = $self->port;

    foreach my $host (@hosts) {
        $self->has_on_before
            and $self->on_before->( $self, $host );

        tcp_connect $host, $port, sub {
            my ($fh) = @_;

            if ( $self->has_on_result ) {
                $self->on_result->( $self, $fh );
            }

            if ( ! defined $fh ) {
                my $error = $!;

                $self->has_on_fail
                    and $self->on_fail->( $self, $error );

                return;
            }

            $self->has_on_success
                and $self->on_success->( $self, $fh );
        }

    }

    return 0;
}

1;

__END__

=head1 DESCRIPTION

    my $juno = Juno->new(
        hosts  => [ 'tom', 'jerry' ],
        checks => {
            TCP => {
                on_success => sub {...},
                on_fail    => sub {...},
            },
        }
    );

=head1 ATTRIBUTES

=head2 hosts

An arrayref of hosts to check, overriding the default given to Juno.pm.

    my $juno = Juno->new(
        hosts  => [ 'Tom', 'Jerry' ],
        checks => {
            TCP => {
                hosts => [ 'Micky', 'Mini' ], # this overrides tom and jerry
            },
        },
    );

Now it will not check Tom and Jerry, but rather Micky and Mini.

This attribute derives from L<Juno::Role::Check>.

=head2 interval

An integer of seconds between each check (nor per-host).

This attribute derives from L<Juno::Role::Check>.

=head2 on_success

A coderef to run when making a successful connection.

This attribute derives from L<Juno::Role::Check>.

=head2 on_fail

A coderef to run when failing to make a connection.

This attribute derives from L<Juno::Role::Check>.

=head2 on_before

A coderef to run before making a request. A useful example of this is timing
the request.

=head2 watcher

Holds the watcher for the HTTP check timer.

This attribute derives from L<Juno::Role::Check>.

=head1 METHODS

=head2 check

L<Juno> will call this method for you. You should not call it yourself.

=head2 run

L<Juno> will call this method for you. You should not call it yourself.

