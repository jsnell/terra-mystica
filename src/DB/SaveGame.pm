#!/usr/bin/perl -w

use strict;
no indirect 'fatal';

package DB::SaveGame;
use Exporter::Easy (EXPORT => [ 'save',
                                'create_game',
                                'verify_and_save',
                                'evaluate_and_save' ]);

use Digest::SHA1 qw(sha1_hex);

use DB::Game;
use DB::IndexGame;
use DB::UserValidate;

use tracker;

sub save {
    my ($dbh, $id, $new_content, $game, $timestamp) = @_;

    my ($read_id) = $id =~ /(.*?)_/g;
    index_game $dbh, $read_id, $id, $game, $timestamp;

    $dbh->do("update game set commands=? where id=?", {},
             $new_content, $read_id);
}

sub verify_email_notification_settings {
    my ($dbh, $game) = @_;

    return if !$game->{options}{'email-notify'};

    for my $faction (values %{$game->{factions}}) {
        if (!$faction->{email}) {
            die "When option email-notify is on, all players must have an email address defined ('$faction->{player}' does not)\n"
        }

        my ($email_valid) =
            $dbh->selectrow_array("select count(*) from email where address=lower(?) and validated=true",
                                  {},
                                  $faction->{email});

        if (!$email_valid) {
            die "When option email-notify is on, all players must be registered ('$faction->{player}' is not)\n"
        }                              
    }
}

sub verify_and_save {
    my ($dbh, $read_id, $write_id, $new_content, $game, $timestamp) = @_;

    for my $faction (values %{$game->{factions}}) {
        if (defined $faction->{email} and !defined $faction->{username}) {
            $faction->{username} = check_email_is_registered $dbh, $faction->{email};
        } elsif (defined $faction->{username}) {
            ($faction->{username},
             $faction->{email}) =
                 check_username_is_registered $dbh, $faction->{username};
        }
    }

    for my $player (@{$game->{players}}) {
        if (defined $player->{email} and !defined $player->{username}) {
            $player->{username} = check_email_is_registered $dbh, $player->{email};
        } elsif (defined $player->{username}) {
            ($player->{username}, $player->{email}) =
                check_username_is_registered $dbh, $player->{username};
        }
    }

    verify_email_notification_settings $dbh, $game;

    save $dbh, $write_id, $new_content, $game, $timestamp;
}

sub evaluate_and_save {
    my ($dbh, $read_id, $write_id, $prefix_content, $new_content) = @_;

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, "$prefix_content\n$new_content" ],
        faction_info => get_game_factions($dbh, $read_id),
        players => get_game_players($dbh, $read_id),
        metadata => get_game_metadata($dbh, $read_id),
        delete_email => 0
    };

    if (!@{$res->{error}}) {
        eval {
            my ($timestamp) =
                $dbh->selectrow_array("select extract(epoch from last_update) from game where id=?",
                                      {},
                                      $read_id);
            if (!defined $timestamp) {
                $timestamp = time;
            }
            verify_and_save $dbh, $read_id, $write_id, $new_content, $res, $timestamp;
        }; if ($@) {
            print STDERR "error: $@\n";
            $res->{error} = [ $@ ]
        }
    };

    $res;
};


sub create_game {
    my ($dbh, $id, $admin_user, $players, $player_count, @options) = @_;

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
 option strict-darkling-sh
 option strict-chaosmagician-sh
 option errata-cultist-power
@options

# Randomize setup
randomize v1 seed $id
EOF
 
    my $write_id = "${id}_${hash}";
    
    $dbh->do(
        'insert into game (id, write_id, finished, round, player_count, wanted_player_count, needs_indexing, admin_user) values  (?, ?, false, 0, ?, ?, false, ?)',
        {},
        $id, $write_id, length @{$players}, $player_count, $admin_user);

    my ($admin_email) = $dbh->selectrow_array("select address from email where player = ? and is_primary", {}, $admin_user);

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
        $dbh->do("insert into game_role (game, email, faction_player, faction, action_required) values (?, lower(?), ?, ?, false)",
                 {},
                 $id,
                 $player->{email},
                 $player->{username},
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
