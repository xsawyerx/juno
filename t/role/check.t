#!perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Fatal;

use Juno;

{
    package Juno::Check::TestCheckZd7DD;
    use Any::Moose;
    with 'Juno::Role::Check';

    sub run {
        my $self = shift;
        Test::More::isa_ok( $self, 'Juno::Check::TestCheckZd7DD' );
        Test::More::ok( $self->does('Juno::Role::Check'), 'Does check role' );

        Test::More::ok( $self->has_on_success, 'Got on_success' );
        Test::More::ok( $self->has_on_fail,    'Got on_fail'    );
        Test::More::ok( $self->has_on_result,  'Got on_result'  );

        Test::More::is(
            $self->on_success->(),
            'success!',
            'Correct on_success',
        );

        Test::More::is(
            $self->on_fail->(),
            'fail!',
            'Correct on_fail',
        );

        Test::More::is(
            $self->on_result->(),
            'result!',
            'Correct on_result',
        );

        Test::More::is_deeply(
            $self->hosts,
            ['A', 'B'],
            'Hosts provided by Juno.pm',
        );
    }
}

{
    package Juno::Check::TestCheckF7A23;
    use Any::Moose;
    with 'Juno::Role::Check';

    sub run {
        my $self = shift;
        Test::More::isa_ok( $self, 'Juno::Check::TestCheckF7A23' );
        Test::More::ok( $self->does('Juno::Role::Check'), 'Does check role' );

        Test::More::is_deeply(
            $self->hosts,
            ['C', 'D'],
            'Hosts were overwritten',
        );
    }
}

my $juno = Juno->new(
    hosts  => ['A', 'B'],
    checks => {
        TestCheckZd7DD => {
            on_success => sub { 'success!' },
            on_fail    => sub { 'fail!'    },
            on_result  => sub { 'result!'  },
        },
    },
);

isa_ok( $juno, 'Juno' );

$juno->run;

$juno = Juno->new(
    hosts  => ['A', 'B'],
    checks => {
        TestCheckF7A23 => {
            hosts => ['C', 'D'],
        },
    },
);

isa_ok( $juno, 'Juno' );
$juno->run;
