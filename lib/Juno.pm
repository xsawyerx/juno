use strict;
use warnings;
package Juno;

use Any::Moose;
use namespace::autoclean;

has checks => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
