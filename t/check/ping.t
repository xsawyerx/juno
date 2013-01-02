#!perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use Juno::Check::Ping;

{
    local $@ = undef;
    eval 'use AnyEvent::Ping';
    $@ and plan skip_all => 'AnyEvent::Ping is required for this test';
}

plan tests => 8;

my @checks_data =	(
						{ host => "127.0.0.1", answer => "OK", },
						{ host => "255.255.255.254", answer => "TIMEOUT", },
					);
sub checks {
    my ( $check, $host, $answer, $supposed_answer ) = @_;

    isa_ok( $check, 'Juno::Check::Ping' );
#    is( $host,  'Correct Host' );
    is( $answer->[0][0], $supposed_answer, "Answer should be '$supposed_answer', Got '$answer->[0][0]'" );
}

my $cv    = AnyEvent->condvar;

for my $check_data ( @checks_data ) {

	# set up 2 points to resolve
	$cv->begin for 1 .. 2;

	my $check = Juno::Check::Ping->new(
		hosts		=> [ $check_data->{ host }, ] ,
		on_success => sub {
			checks(@_, $check_data->{ answer });
			$cv->end;
		},

		on_fail    => sub {
			checks(@_, $check_data->{ answer });
			$cv->end;
		},

		on_result  => sub {
			checks(@_, $check_data->{ answer });
			$cv->end;
		},
	);

	# start check
	$check->run;
}

# wait for test_number*scalar(@array) points to resolve
$cv->recv;

