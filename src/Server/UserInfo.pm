use strict;

package Server::UserInfo;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA1 qw(sha1_hex);

use DB::Connection;
use DB::UserInfo;

method handle($q, $username) {
    $self->no_cache();

    my $dbh = get_db_connection;
    my $res = { error => [] };

    eval {
        $res->{stats} = fetch_user_stats $dbh, $username;
    }; if ($@) {
        $res = { error => [ $@ ] };
    }

    $self->output_json($res);
}

1;
