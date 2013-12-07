#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use JSON;

use db;
use game;
use indexgame;
use notify;
use rlimit;
use save;
use session;
use tracker;

sub error {
    print encode_json {
        error => [ @_ ],
    };
    exit;
};

sub joingame {
    my ($dbh, $read_id, $username)  = @_;
    begin_game_transaction $dbh, $read_id;

    my ($wanted_player_count, $current_count, $already_playing) =
        $dbh->selectrow_array("select wanted_player_count, (select count(*) from game_player where game=game.id), (select count(*) from game_player where game=game.id and player=?) from game where id=?",
                              {},
                              $username,
                              $read_id);

    if (!defined $wanted_player_count) {
        error "Can't join a private game";
    }
    if ($already_playing) {
        error "You've already joined this game";
    }
    if ($wanted_player_count <= $current_count) {
        error "Game is already full";
    }

    $dbh->do("insert into game_player (game, player, sort_key, index) values (?, ?, ?, ?)",
             {},
             $read_id,
             $username,
             $current_count,
             $current_count);

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

my $q = CGI->new;
my $dbh = get_db_connection;

verify_csrf_cookie_or_die $q;

print "Content-Type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');
my $read_id = $q->param('game');

if (!$username) {
    error "not logged in";
}

eval {
    joingame $dbh, $read_id, $username;
}; if ($@) {
    error $@;
}

print encode_json {
    error => []
};
