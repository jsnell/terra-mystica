use strict;

package terra_mystica::Server::Server;

use JSON;
use Moose;
use MooseX::Method::Signatures;

has 'headers' => (is => '',
                  traits => ['Hash'],
                  default => sub { {} },
                  handles => {
                      set_header => 'set',
                      headers => 'elements',
                  });
has 'status' => (is => 'rw',
                 default => 200);
has 'output' => (is => 'rw',
                 default => '');

method output_psgi {
    [$self->status,
     [ $self->headers() ],
     [ $self->output() ]];
};

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
