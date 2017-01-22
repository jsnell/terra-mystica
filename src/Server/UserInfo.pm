use strict;

package Server::UserInfo;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA qw(sha1_hex);

use DB::Connection;
use DB::UserInfo;
use DB::UserValidate;

has 'mode' => (is => 'ro', required => 1);

method handle($q, $query_username) {
    $self->no_cache();

    my $dbh = get_db_connection;

    my $res = { error => [] };

    my $username;

    eval {
        ($username) = check_username_is_registered $dbh, $query_username;
    };

    if ($query_username eq 'top50') {
        $username = $query_username;
    } elsif ($@ or !defined $username) {
        return $self->output_json(
            {
                error => [ "No such user: $query_username" ]
            });
    } elsif ($username ne $query_username) {
        return $self->output_json(
            {
                link => "/player/$username",
                error => [],
            });
    }

    eval {
        if ($self->mode() eq 'stats') {
            $res->{stats} = fetch_user_stats $dbh, $username;
        } elsif ($self->mode() eq 'opponents') {
            $res->{opponents} = fetch_user_opponents $dbh, $username;
        } elsif ($self->mode() eq 'metadata') {
            $self->allow_cross_domain();
            $res->{metadata} = fetch_user_metadata $dbh, $username;
        } else {
            die "unknown mode\n";
        }
    }; if ($@) {
        $res = { error => [ $@ ] };
    }

    $self->output_json($res);
}

1;
