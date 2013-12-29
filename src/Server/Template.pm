use strict;

package Server::Template;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use File::Slurp;
use Server::Session;

method handle($q, $suffix) {
    ensure_csrf_cookie $q, $self;

    my $file;

    if ($suffix eq '') {
        $file = 'index.html';
    } else {
        ($file) = ($suffix =~ m{^([a-z]+)/}g);
        $file .= ".html";
    }

    $self->no_cache();
    $self->output_html(scalar read_file "../$file");
}

1;

