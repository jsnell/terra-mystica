use strict;

package Server::Results;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use DB::Game;
use DB::Secret;

method handle($q, $params) {
    my $dbh = get_db_connection;
    my ($secret, $iv) = get_secret $dbh;
    my %params = ();
    my $version = 'v1';
    my @valid_versions = qw(v1 v2);

    if ($params =~ s{^v(\d+)/}{}) {
        $version = $1;
        my %valid_versions = map { ($_ => 1) } @valid_versions;

        if (!$valid_versions{"v$version"}) {
            die "Invalid version 'v$version'. (Valid values: @valid_versions)\n";
        }
    }

    if ($params =~ m{^(\d+)/(\d+)(?:/(\d+))?$}) {
        %params = (year => $1, month => $2, day => $3);
    } else {
        die "Year/month not specified (e.g. /app/results/$version/2014/01). Day is optional (e.g. /app/results/$version/2014/01/01)\n"
    }

    my $results = {
        version => $version,
        get_finished_game_results $dbh, $secret, %params
    };

    if ($version > 1) {
        $results->{games} = {};
        $results->{players} = {};

        for (@{$results->{results}}) {
            my $game = ($results->{games}{$_->{game}} //= {
                expansion_scoring => $_->{non_standard},
                player_count => $_->{player_count},
                base_map => ($_->{base_map} || '126fe960806d587c78546b30f1a90853b1ada468'),
                options => $_->{options},
                last_update => $_->{last_update},
            });
            delete $_->{options};
            delete $_->{non_standard};
            delete $_->{player_count};   
            delete $_->{last_update};
            delete $_->{base_map};

            $results->{players}{$_->{id_hash}} //= {
                username => $_->{username}
            };
            delete $_->{username};
            delete $_->{game};

            push @{$game->{players}}, $_;
        }

        delete $results->{results};
    }

    $self->output_json($results);
}

1;

