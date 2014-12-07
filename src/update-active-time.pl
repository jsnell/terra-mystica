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
    my $after_soft_deadline_delta = 0;

    if ($row->{seconds_since_update} > 86400) {
        $after_soft_deadline_delta = $interval;
    }

    my $count =
        $dbh->do("update game_active_time set active_seconds=active_seconds + ?, active_after_soft_deadline_seconds=active_after_soft_deadline_seconds + ? where game=? and player=?",
                 {},
                 $delta,
                 $after_soft_deadline_delta,
                 $row->{id},
                 $row->{faction_player});
    if ($count == 0) {
        $dbh->do("insert into game_active_time (active_seconds, active_after_soft_deadline_seconds, game, player) values (?, ?, ?, ?)",
                 {},
                 $delta,
                 $after_soft_deadline_delta,
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
