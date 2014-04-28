use strict;

package Server::SaveGame;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA1 qw(sha1_hex);

use DB::Connection;
use DB::Game;
use DB::SaveGame;
use DB::UserValidate;
use Server::Session;
use tracker;

method handle($q) {
    $self->no_cache();

    my $write_id = $q->param('game');
    $write_id =~ s{.*/}{};
    $write_id =~ s{[^A-Za-z0-9_]}{}g;
    my ($read_id) = $write_id =~ /(.*?)_/g;

    my $orig_hash = $q->param('orig-hash');
    my $new_content = $q->param('content');

    my $dbh = get_db_connection;

    begin_game_transaction $dbh, $read_id;

    my ($prefix_content, $orig_content) =
        get_game_content $dbh, $read_id, $write_id;

    my $res = {};

    if (sha1_hex($orig_content) ne $orig_hash) {
        print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
        $res->{error} = [
            "Someone else made changes to the game. Please reload\n"
            ];
    } else {
        $res = evaluate_and_save $dbh, $read_id, $write_id, $prefix_content, $new_content;
    }

    if (@{$res->{error}}) {
        $dbh->do("rollback");
    } else {
        finish_game_transaction $dbh;
    }

    my $out = {
        error => $res->{error},
        hash => sha1_hex($new_content),
        action_required => $res->{action_required},
        factions => {
            map {
                ($_->{name}, { display => $_->{display}, color => $_->{color} })
            } values %{$res->{factions}}
        },
        players => get_game_players($dbh, $read_id)
    };
    $self->output_json($out);
}

1;
