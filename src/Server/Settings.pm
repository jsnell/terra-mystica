use strict;

package Server::Settings;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA qw(sha1_hex);

use DB::Connection;
use DB::Settings;
use Server::Session;

method handle($q) {
    verify_csrf_cookie_or_die $q, $self;
    $self->no_cache();

    my $dbh = get_db_connection;

    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');

    if (!$username) {
        $self->output_json({
            error => ["Login required"],
            link => "/login/#required",
        });
        return;
    }

    my $res;

    eval {
        if ($q->param('save')) {
            save_user_settings $dbh, $username, $q;
        }

        $res = fetch_user_settings $dbh, $username;
        $res->{error} = [];
    }; if ($@) {
        print STDERR "Settings error: $@\n";
        $res = { error => [ $@ ] };
    }

    $self->output_json($res);
}

1;
