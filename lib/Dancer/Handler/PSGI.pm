package Dancer::Handler::PSGI;

use strict;
use warnings;
use base 'Dancer::Handler';

use Dancer::GetOpt;
use Dancer::Headers;
use Dancer::Config;
use Dancer::ModuleLoader;
use Dancer::SharedData;

sub new {
    my $class = shift;

    die "Plack::Request is needed by the PSGI handler"
        unless Dancer::ModuleLoader->load('Plack::Request');

    my $self  = {};
    bless $self, $class;
    Dancer::Route->init();
    return $self;
}

sub dance {
    my $self = shift;
    return sub {
        my $env = shift;
        my $request = Dancer::Request->new($env);
        $self->init_request_headers($request);
        $self->handle_request($request);
    };
}

sub init_request_headers {
    my ($self, $request) = @_;
    my $env = $request->env;
    my $headers = HTTP::Headers->new(
       map {
       (my $field = $_) =~ s/^HTTPS?_//;
        ( $field => $env->{$_} );
       }
       grep { /^(?:HTTP|CONTENT|COOKIE)/i } keys %$env
    );
    Dancer::SharedData->headers(Dancer::Headers->new(headers => $headers));
    $request->_build_headers();
}

1;
