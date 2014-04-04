use strict;

package Server::UserInfo;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA1 qw(sha1_hex);

use DB::Connection;
use DB::UserInfo;

has 'mode' => (is => 'ro', required => 1);

method handle($q, $username) {
    $self->no_cache();

    my $dbh = get_db_connection;

    my $res = { error => [] };

    eval {
        if ($self->mode() eq 'stats') {
            $res->{stats} = fetch_user_stats $dbh, $username;
        } elsif ($self->mode() eq 'opponents') {
            $res->{opponents} = fetch_user_opponents $dbh, $username;
        } else {
            die "unknown mode\n";
        }
    }; if ($@) {
        $res = { error => [ $@ ] };
    }

    $self->output_json($res);
}

1;
