#!/usr/bin/perl -w

use strict;

use File::Temp qw(tempfile);

use indexgame;

sub save {
    my ($dbh, $id, $new_content, $game, $timestamp) = @_;

    my ($read_id) = $id =~ /(.*?)_/g;
    index_game $dbh, $read_id, $id, $game, $timestamp;

    $dbh->do("update game set commands=? where id=?", {},
             $new_content, $read_id);
}

1;
