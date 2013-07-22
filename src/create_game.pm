#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);

use game;
use indexgame;
use save;

sub create_game {
    my ($dbh, $id, $admin) = @_;

    die "Invalid game id $id\n" if !$id or $id =~ /[^A-Za-z0-9]/;

    my $hash = sha1_hex($id . rand(2**32) . time);
    my $write = "write/${id}_$hash";
    my $read = "read/$id";

    if (game_exists $dbh, $id) {
        die "Game $id already exists\n";
    }

    my $opt_admin = "";
    if ($admin) {
        $opt_admin = "admin email $admin\n\n";
    }

    my $content = <<EOF;
# Game $id

$opt_admin
# List players (in any order) with 'player' command

# Default game options
option errata-cultist-power
# Randomize setup
randomize v1 seed $id
EOF
 
    my $write_id = "${id}_${hash}";
    my $game = $admin ? { admin => $admin } : {};

    save $dbh, $write_id, $content, $game;

    return $write_id;
}

1;
