#!perl

use strict;
use warnings;

use Test::More tests => 1;
use Juno;

my $juno = Juno->new();
isa_ok( $juno, 'Juno' );

