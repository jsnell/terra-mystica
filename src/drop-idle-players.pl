#!/usr/bin/perl -w

use strict;
no indirect;

use File::Basename;
use JSON;

BEGIN { push @INC, dirname $0 }

use DB::Connection;
use DB::Game;
use DB::SaveGame;
use Email::Notify;
use tracker;

my $dbh = get_db_connection;

my $id_pattern = '%';

my $idle_players = $dbh->selectall_arrayref("select game, array_agg(faction) as factions from game_role where game in (select id from game left join game_options on game_options.game=game.id where not finished and not aborted and last_update < now() - coalesce(game_options.deadline_hours, 24*7) * interval '1 hour') and (action_required or leech_required) and game like ? group by game",
                                            { Slice => {} },
                                            $id_pattern);


sub drop_factions_from_game {
    my ($read_id, $factions) = @_;
    my @factions = @{$factions};

    print "Dropping @factions from $read_id\n";

    my ($write_id) = $dbh->selectrow_array("select write_id from game where id=?",
                                           {},
                                           $read_id);

    begin_game_transaction $dbh, $read_id;

    my $players = get_game_players($dbh, $read_id);
    my $metadata = get_game_metadata($dbh, $read_id);

    my ($prefix_content, $new_content) = get_game_content $dbh, $read_id, $write_id;
    my $append = '';
    for my $faction (@factions) {
        $append .= "\ndrop-faction $faction"
    }
    $new_content .= $append;

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, "$prefix_content\n$new_content" ],
        faction_info => get_game_factions($dbh, $read_id),
        players => $players,
        metadata => $metadata,
        delete_email => 0
    };

    if (@{$res->{error}}) {
        die join "\n", @{$res->{error}};
    }

    save $dbh, $write_id, $new_content, $res;

    finish_game_transaction $dbh;

    if ($res->{options}{'email-notify'}) {
        my $factions = $dbh->selectall_arrayref(
            "select game_role.faction as name, email.address as email, player.displayname from game_role left join email on email.player = game_role.faction_player left join player on player.username = game_role.faction_player where game = ? and email.is_primary",
            { Slice => {} },
            $read_id);
        for my $faction (@{$factions}) {
            my $eval_faction = $res->{factions}{$faction->{name}};
            if ($eval_faction) {
                $faction->{recent_moves} = $eval_faction->{recent_moves};
                $faction->{VP} = $eval_faction->{VP};
            }
        }
        my $game = {
            name => $read_id,
            factions => { map { ($_->{name}, $_) } @{$factions} },
            finished => $res->{finished},
            options => $res->{options},
            action_required => $res->{action_required},
        };
        notify_after_move $dbh, $write_id, $game, $factions[0], $append;
    }
};

for (@{$idle_players}) {
    eval {
        drop_factions_from_game $_->{game}, $_->{factions};
    }; if ($@) {
        print "Error in game $_->{game}: $@"
    }
}

