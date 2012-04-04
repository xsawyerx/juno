#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;

use Juno;

{
    package Juno::Check::TestCheckZd7DD;
    use Any::Moose;
    with 'Juno::Role::Check';

    has testattr => ( is => 'ro', isa => 'Str' );

    sub run {
        my $self = shift;
        Test::More::isa_ok( $self, 'Juno::Check::TestCheckZd7DD' );
        Test::More::is( $self->testattr, 'testval', 'Got test attr value' );
    }
}

my $juno = Juno->new(
    checks => {
        TestCheckZd7DD => {
            testattr => 'testval',
        },
    },
);

isa_ok( $juno, 'Juno' );
can_ok( $juno, 'run'  );

$juno->run;

