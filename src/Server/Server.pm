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
has 'cookies' => (is => 'rw',
                  default => sub { {} });
                  
method set_header($header, $value) {
    $self->push_header($header);
    $self->push_header($value);
}

method output_psgi {
    [$self->status,
     [ $self->headers() ],
     [ $self->output() ]];
};

method redirect($where) {
    $self->status(303);
    $self->set_header("Location", $where);
}

method allow_cross_domain($where) {
    $self->set_header("Access-Control-Allow-Origin", "*");
}

method no_cache() {
    $self->set_header("Cache-Control", "no-cache");
}

method output_json($data) {
    $self->output_cookies();
    $self->set_header("Content-type", "application/json");
    $self->output(encode_json($data));
}

method output_html($data) {
    $self->output_cookies();
    $self->set_header("Content-type", "text/html");
    $self->output($data);
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

method output_cookies() {
    for my $key (keys %{$self->cookies()}) {
        my $data = $self->cookies()->{$key};
        my $value = $data->[0];
        my @attributes = @{$data->[1]};
        $self->set_header("Set-Cookie",
                          join '; ', "$key=$value", @attributes);
    }
}

method set_cookie($field, $value, $attributes) {
    $self->cookies()->{$field} = [$value, $attributes];
}

1;
