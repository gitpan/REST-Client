use strict;
use warnings;

unshift @INC, "../lib";

my $how_many;
my $have_server;

BEGIN {
    $how_many = 37;
    eval { require HTTP::Server::Simple; };
    $have_server = $@ ? 0 : 1;
}

use Test::More tests => $how_many;

SKIP: {
    skip( 'No HTTP::Server::Simple, can\'t test', $how_many )
      unless $have_server;

    use_ok('REST::Client');

    my $port = 7657;
    my $pid  = REST::Client::TestServer->new($port)->background();

    eval {

        # Initializing and configuring
        my $client = REST::Client->new();
        ok( $client, "Client returned from new()" );
        ok(
            ref($client) =~ /REST::Client/,
            "Client returned from new() is blessed"
        );

        my $config = {
            host    => 'https://example.com',
            cert    => '/path/to/ssl.crt',
            key     => '/path/to/ssl.key',
            ca      => '/path/to/ca.file',
            timeout => 10,
        };

        $client = REST::Client->new($config);

        is( $client->getHost(), $config->{'host'}, 'host accessor works' );
        is( $client->getCert(), $config->{'cert'}, 'cert accessor works' );
        is( $client->getKey(),  $config->{'key'},  'key accessor works' );
        is( $client->getCa(),   $config->{'ca'},   'ca accessor works' );
        is( $client->getTimeout(), $config->{'timeout'},
            'timeout accessor works' );

        $config = {
            host    => 'http://example.com',
            cert    => '/path/from/ssl.crt',
            key     => '/path/from/ssl.key',
            ca      => '/path/from/ca.file',
            timeout => 60,
        };

        is( $client->setHost( $config->{'host'} ),
            $config->{'host'}, 'host setter works' );
        is( $client->setCert( $config->{'cert'} ),
            $config->{'cert'}, 'cert setter works' );
        is( $client->setKey( $config->{'key'} ),
            $config->{'key'}, 'key setter works' );
        is( $client->setCa( $config->{'ca'} ),
            $config->{'ca'}, 'ca setter works' );
        is( $client->setTimeout( $config->{'timeout'} ),
            $config->{'timeout'}, 'timeout setter works' );

        is( $client->getHost(), $config->{'host'}, 'host accessor works' );
        is( $client->getCert(), $config->{'cert'}, 'cert accessor works' );
        is( $client->getKey(),  $config->{'key'},  'key accessor works' );
        is( $client->getCa(),   $config->{'ca'},   'ca accessor works' );
        is( $client->getTimeout(), $config->{'timeout'},
            'timeout accessor works' );

        # Basic requests

        $client = REST::Client->new( { host => "127.0.0.1:$port", } );

        is( $client->GET("/"),     $client, "Client returns self" );
        is( $client->PUT("/"),     $client, "Client returns self" );
        is( $client->POST("/"),    $client, "Client returns self" );
        is( $client->DELETE("/"),  $client, "Client returns self" );
        is( $client->OPTIONS("/"), $client, "Client returns self" );
        is( $client->HEAD("/"),    $client, "Client returns self" );
        is( $client->request( 'GET', "/", '', {} ),
            $client, "Client returns self" );

        my $path = "/ok/" . time() . "/";
        is( $client->GET($path)->responseContent(),
            $path, "GET content present" );
        is( $client->PUT($path)->responseContent(),
            $path, "PUT content present" );
        is( $client->POST($path)->responseContent(),
            $path, "POST content present" );
        is( $client->DELETE($path)->responseContent(),
            $path, "DELETE content present" );
        is( $client->OPTIONS($path)->responseContent(),
            $path, "OPTIONS content present" );
        is( $client->HEAD($path)->responseContent(),
            '', "HEAD content present" );
        is( $client->request( 'GET', $path, '', {} ),
            $client, "request() content present" );

        is( $client->GET($path)->responseCode(), 200, "Success code" );
        $path = "/error/";
        is( $client->GET($path)->responseCode(), 400, "Error code" );
        $path = "/bogus/";
        is( $client->GET($path)->responseCode(), 404, "Not found code" );

        ok(scalar($client->responseHeaders()), 'Header names available');
        ok( $client->responseHeader('Client-Response-Num'), 'Can pull a header');


    };

    warn "Tests died: $@" if $@;

    kill 15, $pid;

}
exit;

package REST::Client::TestServer;

BEGIN{
    eval 'require HTTP::Server::Simple::CGI;';
    our @ISA = qw(HTTP::Server::Simple::CGI);
}

sub handle_request {
    my ( $self, $cgi ) = @_;

    my $path = $cgi->path_info();
    if ( $path =~ /ok/ ) {
        print "HTTP/1.0 200 OK\r\n";
    }
    elsif ( $path =~ /error/ ) {
        print "HTTP/1.0 400 ERROR\r\n";
    }
    else {
        print "HTTP/1.0 404 NOT FOUND\r\n";
    }
    print "\n$path";
}

sub valid_http_method {
    my $self = shift;
    my $method = shift or return 0;
    return $method =~ /^(?:GET|POST|HEAD|PUT|DELETE|OPTIONS)$/;
}

1;
