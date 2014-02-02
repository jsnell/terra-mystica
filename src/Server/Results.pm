use strict;

package Server::Results;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use DB::Game;
use DB::Secret;

method handle($q) {
    my $dbh = get_db_connection;
    my ($secret, $iv) = get_secret $dbh;
    my $results = { get_finished_game_results $dbh, $secret };
    
    $self->output_json($results);
}

1;

