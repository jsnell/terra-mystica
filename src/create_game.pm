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

    my $content = <<EOF;
# Default game options
 option strict-leech
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
        $dbh->do("insert into game_player (game, player, sort_key, index) values (?, ?, ?, ?)",
                 {},
                 $id,
                 $player->{username},
                 $i,
                 $i);
        # Different indexing, sigh
        ++$i;
        $dbh->do("insert into game_role (game, email, faction, action_required) values (?, lower(?), ?, false)",
                 {},
                 $id,
                 $player->{email},
                 "player".($i));
    }

    my $prefix_content = "";
    if (defined $player_count) {
        die "Invalid player-count '$player_count'\n" if $player_count < 2 or $player_count > 5;
        $prefix_content = "player-count $player_count\n";
    }

    evaluate_and_save $dbh, $id, $write_id, $prefix_content, $content;

    return $write_id;
}

1;
