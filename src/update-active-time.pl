#!/usr/bin/perl -lw

use strict;
use JSON;
use POSIX;
use File::Basename qw(dirname);

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;
use DB::Game;
use tracker;

my $dbh = get_db_connection;

# Run every 10 minutes.
my $interval = 10*60;

sub handle {
    my ($row) = @_;

    my $delta = $interval;
    my @delta = (0, 0, 0, 0, 0, 0);

    if ($row->{seconds_since_update} < $interval) {
        return;
    }

    if ($row->{seconds_since_update} > 4*3600) {
        $delta[0] = $interval;
    }
    if ($row->{seconds_since_update} > 8*3600) {
        $delta[1] = $interval;
    }
    if ($row->{seconds_since_update} > 12*3600) {
        $delta[2] = $interval;
    }
    if ($row->{seconds_since_update} > 24*3600) {
        $delta[3] = $interval;
    }
    if ($row->{seconds_since_update} > 48*3600) {
        $delta[4] = $interval;
    }
    if ($row->{seconds_since_update} > 72*3600) {
        $delta[5] = $interval;
    }

    my $count =
        $dbh->do("update game_active_time set active_seconds=active_seconds + ?, active_seconds_4h=active_seconds_4h+?, active_seconds_8h=active_seconds_8h+?, active_seconds_12h=active_seconds_12h+?, active_seconds_24h=active_seconds_24h+?,active_seconds_48h=active_seconds_48h+?, active_seconds_72h=active_seconds_72h+? where game=? and player=?",
                 {},
                 $delta,
                 @delta,
                 $row->{id},
                 $row->{faction_player});

    if ($count == 0) {
        $dbh->do("insert into game_active_time (active_seconds, active_seconds_4h, active_seconds_8h, active_seconds_12h, active_seconds_24h, active_seconds_72h, active_seconds_48h, game, player) values (?, ?, ?, ?)",
                 {},
                 $delta,
                 @delta,
                 $row->{id},
                 $row->{faction_player});
    }
}

$dbh->do("begin");

my $games = $dbh->selectall_arrayref("select game.id, extract(epoch from now() - game.last_update) as seconds_since_update, game_role.faction_player from game left join game_role on game_role.game=game.id where not finished and (game_role.action_required or game_role.leech_required) and game.id like ? and game_role.faction_player is not null",
                                     { Slice => {} },
                                     shift || '%');

for (@{$games}) {
    handle $_;
}

$dbh->do("commit");
