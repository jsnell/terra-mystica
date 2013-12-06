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

my $q = CGI->new;
my $dbh = get_db_connection;

verify_csrf_cookie_or_die $q;

print "Content-Type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');
my $read_id = $q->param('game');

begin_game_transaction $dbh, $read_id;

my $write_id = $dbh->selectrow_array("select write_id from game where id=?",
                                     {},
                                     $read_id);
my ($orig_content) = get_game_content $dbh, $read_id, $write_id;

my  $content ="player $username username $username\n$orig_content";

my $res = terra_mystica::evaluate_game {
    rows => [ split /\n/, "$content\n" ],
    players => get_game_players($dbh, $read_id),
    delete_email => 0
};

if (!defined $res->{player_count}) {
    $res->{error} = ["Can't join a private game"];
} elsif ($res->{player_count} < @{$res->{players}}) {
    $res->{error} = ["Game is already full"];
} elsif (1 != grep { ($_->{username} // '') eq $username } @{$res->{players}}) {
    $res->{error} = ["You have already joined this game"];
} elsif (@{$res->{error}}) {
    $res->{error} = ["Unknown error when joining game"]
} 

for my $player (@{$res->{players}}) {
    next if !defined $player->{username} or $player->{username} ne $username;
    ($player->{username}, $player->{email}) =
        check_username_is_registered $dbh, $player->{username};
}

if (!@{$res->{error}}) {
    eval {
        save $dbh, $write_id, $content, $res, 0;
        if ($res->{player_count} == @{$res->{players}}) {
            notify_game_started $dbh, {
                name => $read_id,
                players => $res->{players},
            }
        }
    }; if ($@) {
        print STDERR "error: $@\n";
        $res->{error} = [ $@ ]
    }
};

finish_game_transaction $dbh;

## FIXME: send an email when game starts

my $out = encode_json {
    error => $res->{error},
};
print $out;
