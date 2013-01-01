#!perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use Juno::Check::Ping;

#{
#    local $@ = undef;
#    eval 'use Test::TCP';
#    $@ and plan skip_all => 'Test::TCP is required for this test';
#}

{
    local $@ = undef;
    eval 'use AnyEvent::Ping';
    $@ and plan skip_all => 'AnyEvent::Ping is required for this test';
}

#plan tests => 16;
plan tests => 8;

my @checks_data =	(
						{ host => v127.0.0.1, answer => "OK", },
						{ host => v127.1.1.1, answer => "TIMEOUT", },
					);

sub checks {
    my ( $check, $host, $answer, $supposed_answer ) = @_;

    isa_ok( $check, 'Juno::Check::Ping' );
#    is( $host,  'Correct Host' );
	is( $answer->[0][0], $supposed_answer, "Ping answer is correct ($answer)" );
}

my $cv    = AnyEvent->condvar;

for my $check_data ( @check ) {

	# set up 2 points to resolve
	$cv->begin for 1 .. 2;

	my $check = Juno::Check::Ping->new(
		hosts		=> $check_data->{ host } ,
		on_success => sub {
			checks(@_, $checks_data->{ answer });
			$cv->end;
		},

		on_fail    => sub {
			checks(@_, $checks_data->{ answer });
			$cv->end;
		},

		on_result  => sub {
			checks(@_, $checks_data->{ answer });
			$cv->end;
		},
	);

	# start check
	$check->run;
}

# wait for test_number*scalar(@array) points to resolve
$cv->recv;

