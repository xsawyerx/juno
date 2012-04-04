#!perl

use strict;
use warnings;

use Test::More tests => 9;
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
    }
}

my $juno = Juno->new(
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
