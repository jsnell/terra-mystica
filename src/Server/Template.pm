use strict;

package Server::Template;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use File::Slurp;
use Server::Session;
use Util::PageGenerator;

method handle($q, $suffix) {
    ensure_csrf_cookie $q, $self;

    if (!$suffix) {
        $suffix = 'index';
    }

    $suffix =~ s{/.*}{}g;

    $self->no_cache();
    $self->output_html(generate_page '..', $suffix);
}

1;

