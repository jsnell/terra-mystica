#!/usr/bin/perl -w

use strict;

use File::Slurp qw(read_file);
use File::Basename;

BEGIN { push @INC, dirname $0 }

use DB::Connection;
use DB::Game;
use DB::SaveGame;
use tracker;

my $dbh = get_db_connection;

sub evaluate_and_index_game {
    my ($read_id, $write_id, $timestamp) = @_;

    print "$read_id\n";

    begin_game_transaction $dbh, $read_id;

    my ($prefix_content, $orig_content) =
        get_game_content $dbh, $read_id, $write_id;

    my $res = evaluate_and_save $dbh, $read_id, $write_id, $prefix_content, $orig_content;

    finish_game_transaction $dbh;
}

my $pattern = shift;
die "Usage: $0 pattern\n" if !$pattern;

my $games = $dbh->selectall_arrayref("select id, write_id, extract(epoch from last_update) from game where id like ?",
                                     {},
                                     $pattern);

for (@{$games}) {
    evaluate_and_index_game @{$_};
}

