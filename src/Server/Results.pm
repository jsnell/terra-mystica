use strict;

package Server::Results;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use DB::Game;
use DB::Secret;

method handle($q, $month) {
    my $dbh = get_db_connection;
    my ($secret, $iv) = get_secret $dbh;
    my %params = ();

    if ($month =~ m{^(\d+)/(\d+)(?:/(\d+))?$}) {
        %params = (year => $1, month => $2, day => $3);
    } else {
        die "Year/month not specified (e.g. /app/results/2014/01). Day is optional (e.g. /app/results/2014/01/01)\n"
    }

    my $results = { get_finished_game_results $dbh, $secret, %params };

    for (@{$results->{results}}) {
        delete $_->{base_map};
    }
    
    $self->output_json($results);
}

1;

