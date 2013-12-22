use strict;

package Server::Template;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use File::Slurp;
use Server::Session;

method handle($q) {
    ensure_csrf_cookie $q, $self;

    my $path_info = $q->path_info();
    my $file;

    $path_info =~ s{/template/}{/};

    if ($path_info eq '/') {
        $file = 'index.html';
    } else {
        ($file) = ($path_info =~ m{^/([a-z]+)/}g);
        $file .= ".html";
    }

    $self->no_cache();
    $self->output_html(scalar read_file "../$file");
}

1;

