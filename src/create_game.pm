#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);

use game;
use indexgame;
use save;

sub create_game {
    my ($dbh, $id, $admin, $players, $player_count, @options) = @_;

    die "Invalid game id $id\n" if !$id or $id =~ /[^A-Za-z0-9]/;

    my $hash = sha1_hex($id . rand(2**32) . time);
    my $write = "write/${id}_$hash";
    my $read = "read/$id";

    if (game_exists $dbh, $id) {
        die "Game $id already exists\n";
    }

    @options = map { s/\s+//g; "option $_\n" } @options;
    my @players = map {
        "player $_->{username} username $_->{username}\n";
    } @{$players};

    if (defined $player_count) {
        push @players, "player-count $player_count";
    }

    my $content = <<EOF;
# List players (in any order) with 'player' command
 @players

# Default game options
 @options

# Randomize setup
randomize v1 seed $id
EOF
 
    my $write_id = "${id}_${hash}";
    
    $dbh->do(
        'insert into game (id, write_id, finished, round, player_count, wanted_player_count, needs_indexing) values  (?, ?, false, 0, ?, ?, false)',
        {},
        $id, $write_id, length @{$players}, $player_count);

    $dbh->do("insert into game_role (game, email, faction, action_required) values (?, lower(?), 'admin', false)",
             {},
             $id,
             $admin);

    my $i = 0;
    for my $player (sort { $a->{username} cmp $b->{username} } @{$players}) {
        $dbh->do("insert into game_role (game, email, faction, action_required) values (?, lower(?), ?, false)",
                 {},
                 $id,
                 $player->{email},
                 "player".(++$i));
    }

    evaluate_and_save $dbh, $id, $write_id, $content;

    return $write_id;
}

1;
