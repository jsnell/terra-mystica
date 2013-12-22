use strict;

package Server::Server;

use JSON;
use Moose;
use Method::Signatures::Simple;

has 'headers' => (is => '',
                  traits => ['Array'],
                  default => sub { [] },
                  handles => {
                      headers => 'elements',
                      push_header => 'push',
                  });
has 'status' => (is => 'rw',
                 default => 200);
has 'output' => (is => 'rw',
                 default => '');

method set_header($header, $value) {
    $self->push_header($header);
    $self->push_header($value);
}

method output_psgi {
    [$self->status,
     [ $self->headers() ],
     [ $self->output() ]];
};

method no_cache() {
    $self->set_header("Cache-Control", "no-cache");
}

method output_json($data) {
    $self->set_header("Content-type", "application/json");
    $self->output(encode_json($data));
}

method handle($q) {
    die "Server::Server::handle() not implemented";
}

around handle => sub {
    my ($orig, $self, @args) = @_;
    eval {
        $self->$orig(@args);
    }; if ($@) {
        $self->status(500);
        $self->output_json({ error => [ "$@" ] });
    }
};

1;
