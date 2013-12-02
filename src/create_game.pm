#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);

use game;
use indexgame;
use save;

sub create_game {
    my ($dbh, $id, $admin, $players, @options) = @_;

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

    @options = map { s/\s+//g; "option $_\n" } @options;
    my @players = map {
        "player $_ username $_\n";
    } @{$players};

    my $content = <<EOF;
# Game $id

$opt_admin
# List players (in any order) with 'player' command
 @players

# Default game options
 @options

# Randomize setup
randomize v1 seed $id
EOF
 
    my $write_id = "${id}_${hash}";

    evaluate_and_save $dbh, $id, $write_id, $content;

    return $write_id;
}

1;
