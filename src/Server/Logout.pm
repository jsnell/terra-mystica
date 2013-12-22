use strict;

package Server::Logout;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

method handle($q) {
    $self->no_cache();
    $self->set_header("Set-Cookie", "csrf-token=; Path=/");
    $self->set_header("Set-Cookie", "session-username=; Path=/");
    $self->set_header("Set-Cookie", "session-token=; Path=/; HttpOnly");
    $self->redirect("/");
}

1;

