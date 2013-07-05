#!/usr/bin/perl -w

use strict;

use File::Slurp qw(read_file);
use File::Basename;

BEGIN { push @INC, dirname $0 }

use db;
use game;
use indexgame;
use tracker;

my $dbh = get_db_connection;

sub evaluate_and_index_game {
    my ($id, $write_id, $timestamp) = @_;

    print "$id\n";

    begin_game_transaction $dbh, $id;

    my @rows = get_game_commands $dbh, $id, $write_id;

    my $game = terra_mystica::evaluate_game {
        rows => [ @rows ],
        delete_email => 0
    };

    index_game $dbh, $id, $write_id, $game, $timestamp;

    finish_game_transaction $dbh;
}

my $games = $dbh->selectall_arrayref("select id, write_id, extract(epoch from last_update) from game where id like ?",
                                     {},
                                     shift || '%');

for (@{$games}) {
    evaluate_and_index_game @{$_};
}

