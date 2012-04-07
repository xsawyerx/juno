#!perl

use strict;
use warnings;

use Test::More;

use AnyEvent;
use Juno::Check::HTTP;

{
    local $@ = undef;
    eval 'use Test::TCP';
    $@ and plan skip_all => 'Test::TCP is required for this test';
}

{
    local $@ = undef;
    eval 'use AnyEvent::HTTPD';
    $@ and plan skip_all => 'AnyEvent::HTTPD is required for this test';
}

plan tests => 16;

my $mainbody = '<html><head><body>OK</body></head></html>';
my $port     = Test::TCP::empty_port();
my $httpd    = AnyEvent::HTTPD->new( port => $port );
$httpd->reg_cb (
    '/' => sub {
        my ( $httpd, $req ) = @_;
 
        $req->respond( {
            content => [
                'text/html',
                $mainbody,
            ],
        } );
   },
);

sub checks {
    my ( $check, $host, $body, $headers ) = @_;

    isa_ok( $check, 'Juno::Check::HTTP' );
    like( $host, qr/^(?:localhost|\Q127.0.0.1\E):$port$/, 'Correct Host' );
    is( $body, $mainbody, 'Got body' );

    # possibly remove dates from headers because it can't be static
    delete $headers->{'date'};
    delete $headers->{'expires'};

    is_deeply(
        $headers,
        {
          "cache-control"  => "max-age=0",
          "connection"     => "Keep-Alive",
          "content-length" => 41,
          "content-type"   => "text/html",
          "HTTPVersion"    => "1.0",
          "Reason"         => "ok",
          "Status"         => 200,
          "URL"            => "http://$host/",
        },
        'Got correct headers',
    );
};

my $cv    = AnyEvent->condvar;
my $check = Juno::Check::HTTP->new(
    hosts      => [ "localhost:$port", "127.0.0.1:$port" ],
    headers    => { 'Num' => 30, 'String' => 'hello' },
    on_success => sub {
        checks(@_);
        $cv->end;
    },

    on_fail    => sub {
        checks(@_);
        $cv->end;
    },

    on_result  => sub {
        checks(@_);
        $cv->end;
    },
);

# set up 3 points to resolve
$cv->begin for 1 .. 3;

# start check
$check->run;

# wait for 3 points to resolve
$cv->recv;

