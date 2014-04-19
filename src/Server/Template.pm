use strict;

package Server::Template;

use JSON;
use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use Server::Session;
use Util::PageGenerator;

method handle($q, $suffix) {
    ensure_csrf_cookie $q, $self;

    if (!$suffix) {
        $suffix = 'index';
    }

    $suffix =~ s{/.*}{}g;

    my $dbh = get_db_connection;
    my $params = {
        username => username_from_session_token($dbh,
                                                $q->cookie('session-token') // '') // '',

        access => username_from_session_token($dbh,
                                              $q->cookie('access-token') // '') // '',
    };

    $self->no_cache();
    $self->output_html(generate_page '..', $suffix, $params);
}

1;

