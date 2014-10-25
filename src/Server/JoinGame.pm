use strict;
no indirect;

package Server::JoinGame;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use DB::Game;
use DB::IndexGame;
use DB::SaveGame;
use DB::UserInfo;
use Email::Notify;
use Server::Session;
use tracker;

sub joingame {
    my ($dbh, $read_id, $username)  = @_;
    begin_game_transaction $dbh, $read_id;

    my ($wanted_player_count, $current_count, $already_playing,
        $minimum_rating, $maximum_rating) =
        $dbh->selectrow_array("select wanted_player_count, (select count(*) from game_player where game=game.id), (select count(*) from game_player where game=game.id and player=?), game_options.minimum_rating, game_options.maximum_rating from game left join game_options on game.id=game_options.game where id=?",
                              {},
                              $username,
                              $read_id);

    if (!defined $wanted_player_count) {
        die "Can't join a private game\n";
    }
    if ($already_playing) {
        die "You've already joined this game\n";
    }
    if ($wanted_player_count <= $current_count) {
        die "Game is already full\n";
    }

    {
        my $user_metadata = fetch_user_metadata $dbh, $username;
        my $user_rating = ($user_metadata->{rating} // 0);
        if ($user_rating < ($minimum_rating // 0)) {
            die "Your rating ($user_rating) is too low to join\n";
        }
        if ($user_rating > ($maximum_rating // 1e6)) {
            die "Your rating ($user_rating) is too high to join\n";
        }
    }

    $dbh->do("insert into game_player (game, player, sort_key, index) values (?, ?, ?, ?)",
             {},
             $read_id,
             $username,
             $current_count,
             $current_count);
    $dbh->do("update game set last_update = now() where id = ?",
             {},
             $read_id);

    if ($wanted_player_count == $current_count + 1) {
        my $write_id = $dbh->selectrow_array("select write_id from game where id=?",
                                             {},
                                             $read_id);
        my ($prefix_content, $orig_content) =
            get_game_content $dbh, $read_id, $write_id;

        my $res = evaluate_and_save $dbh, $read_id, $write_id, $prefix_content, $orig_content;
        notify_game_started $dbh, {
            name => $read_id,
            options => $res->{options},
            players => $res->{players},
        }
    }

    finish_game_transaction $dbh;
}

method handle($q) {
    my $dbh = get_db_connection;

    $self->no_cache();
    verify_csrf_cookie_or_die $q, $self;

    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');
    my $read_id = $q->param('game');
    my $res = {
        error => [],
    };

    if (!$username) {
        $res->error = [ "not logged in" ];
    } else {
        eval {
            joingame $dbh, $read_id, $username;
        }; if ($@) {
            $res->{error} = [ $@ ];
        }
    }

    $self->output_json($res);
}

1;

