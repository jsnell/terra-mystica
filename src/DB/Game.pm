#!/usr/bin/perl -w

package DB::Game;
use Exporter::Easy (
    EXPORT => [qw(game_exists
                  get_game_content
                  get_game_commands
                  get_game_factions
                  get_game_players
                  get_game_metadata
                  begin_game_transaction
                  finish_game_transaction
                  get_chat_count
                  get_finished_game_results
                  get_open_game_list
                  get_user_game_list
                  abort_game
                  unabort_game
                )]
    );

use strict;

use DBI;
use Digest::SHA1 qw(sha1_hex);

use DB::EditLink;
use Util::NaturalCmp;

sub game_exists {
    my ($dbh, $id) = @_;

    $dbh->selectrow_array("select count(*) from game where id=?",
                          {},
                          $id);
}

sub get_game_content {
    my ($dbh, $id, $write_id) = @_;

    my ($actual_write_id, $content, $wanted_player_count) =
        $dbh->selectrow_array(
            "select write_id, commands, wanted_player_count from game where id=?",
            {},
            $id);

    if (defined $write_id) {
        if ($write_id ne $actual_write_id) {
            die "Invalid write_id $write_id"
        }
    } else {
        $content =~ s/email(?!-)\s*\S+/email redacted/g;
    }

    my $prefix_content = "";
    if (defined $wanted_player_count) {
        $prefix_content = "player-count $wanted_player_count\n";
    }

    return ($prefix_content, $content);
}

sub get_game_commands {
    my ($prefix_content, $content) = get_game_content @_;
    split /\n/, "$prefix_content\n$content\n";
}

sub get_game_factions {
    my ($dbh, $id) = @_;

    my ($rows) =
        $dbh->selectall_hashref("select game_role.faction, player.username, game_role.email, player.displayname from email inner join game_role on game_role.email=email.address inner join player on player.username=email.player where game_role.game=? and game_role.faction != 'admin'",
                                'faction',
                                 { Slice => {} },
                                 $id);
    $rows;
}

sub get_game_players {
    my ($dbh, $id) = @_;

    my ($rows) =
        $dbh->selectall_arrayref("select game_player.player as username, game_player.sort_key as name, game_player.index as index, player.displayname as displayname from game_player left join player on game_player.player=player.username where game=? order by index",
                                 { Slice => {} },
                                 $id);

    $rows;
}

sub get_game_metadata {
    my ($dbh, $id) = @_;

    my ($rows) =
        $dbh->selectall_arrayref("select extract(epoch from now() - last_update) as time_since_update, description, finished, aborted, game_options, player_count, wanted_player_count, base_map as map_variant from game where id=?",
                                 { Slice => {} },
                                 $id);

    my $res = $rows->[0];

    if ($res->{map_variant}) {        
        my ($map_str) = $dbh->selectrow_array("select terrain from map_variant where id=?", {}, $res->{map_variant});
        $res->{base_map} = [ split /\s+/, $map_str ];
    }


    $res;
}

sub begin_game_transaction {
    my ($dbh, $id) = @_;

    $dbh->do("begin");
    $dbh->do("select * from game where id=? for update",
             {},
             $id);
}

sub finish_game_transaction {
    my ($dbh) = @_;

    $dbh->do("commit");
}

sub get_chat_count {
    my ($dbh, $id, $username) = @_;

    my $count = $dbh->selectrow_array("select count(*) from chat_message where game=?",
                                      {},
                                      $id);
    my $unread_count = 0;

    if ($username) {
        $unread_count = $dbh->selectrow_array("select count(*) from chat_message where game=? and posted_at > (select coalesce((select last_read from chat_read where game=chat_message.game and player=?), '2012-01-01'))",
                                              {},
                                              $id,
                                              $username);
    }

    ($count, $unread_count);
}

sub get_finished_game_results {
    my ($dbh, $secret, $id_pattern) = @_;

    my %res = ( error => '', results => [] );

    $dbh->do('begin');

    # Filter out games by some dicks who are getting their kicks by
    # distorting the stats with ridiculous games.
    $dbh->do("update game set exclude_from_stats=true where id in (select id from game left join game_role on game.id = game_role.game left join blacklist on game_role.email=blacklist.email where game_role.faction='admin' and blacklist.email is not null)");

    my $rows = $dbh->selectall_arrayref(
        "select game, faction, vp, rank, start_order, email.player, email, game.player_count, game.last_update, game.non_standard from game_role left join game on game=game.id left join email on email=email.address where faction != 'admin' and game.finished and game.round=6 and not game.aborted and not game.exclude_from_stats and game.id like ?",
        {},
        $id_pattern || '%');

    if (!$rows) {
        $res{error} = "db error";
    } else {
        for (@{$rows}) {
            push @{$res{results}}, {
                game => $_->[0],
                faction => $_->[1],
                vp => $_->[2],
                rank => $_->[3],
                start_order => $_->[4],
                username => $_->[5],
                id_hash => ($_->[6] ? sha1_hex($_->[6] . $secret) : undef),
                player_count => $_->[7],
                last_update => $_->[8],
                non_standard => $_->[9]
            }
        }
    }

    $dbh->do('commit');

    $dbh->disconnect();

    %res;
}

sub get_open_game_list {
    my ($dbh) = @_;

    my $games = $dbh->selectall_arrayref(
        "select game.id, game.player_count, game.wanted_player_count, game.description, array(select player from game_player where game_player.game=game.id) as players, game_options from game where game.wanted_player_count is not null and game.player_count != game.wanted_player_count and not game.finished",
        { Slice => {} }
        );

    $games;
}

sub sorted_user_games {
    [ sort {
        ($b->{action_required}) <=> ($a->{action_required}) or
        ($a->{finished}) <=> ($b->{finished}) or
        ($a->{seconds_since_update} // 1e12) <=> ($b->{seconds_since_update} // 1e12) or
        natural_cmp $a->{id}, $b->{id};
      } @_
    ];
}

sub role_link {
    my ($dbh, $record) = @_;
    if ($record->{faction} eq 'admin') {
        "/edit/$record->{write_id}";
    } else {
        edit_link_for_faction $dbh, $record->{write_id}, $record->{faction};
    }
}

sub get_player_game_list {
    my ($dbh, $user, $mode, $status) = @_;

    my $roles = $dbh->selectall_arrayref(
        "select game, faction, game.write_id, game.finished, action_required, (extract(epoch from now() - game.last_update)) as time_since_update, vp, rank, (select faction from game_role as gr2 where gr2.game = gr1.game and action_required limit 1) as waiting_for, leech_required, game.round, (select count(*) from chat_message where game=game.id and posted_at > (select coalesce((select last_read from chat_read where game=chat_message.game and player=?), '2012-01-01'))) as unread_chat, game.aborted, gr1.dropped from game_role as gr1 left join game on game=game.id where email in (select address from email where player = ?) and (game.finished = ? or (game.finished and last_update > now() - interval '2 days')) and (gr1.faction != 'admin')",
        { Slice => {} },
        $user, $user, $status);
    sorted_user_games (map {
        { id => $_->{game},
          role => $_->{faction},
          link => ($mode eq 'other-user' ? "/game/$_->{game}" : role_link($dbh, $_)),
          finished => $_->{finished} ? 1 : 0,
          action_required => !$_->{aborted} && ($_->{action_required} || $_->{leech_required}) || 0,
          seconds_since_update => $_->{time_since_update},
          vp => $_->{vp},
          rank => $_->{rank},
          waiting_for => $_->{waiting_for},
          round => $_->{round},
          unread_chat_messages => 1*$_->{unread_chat},
          aborted => $_->{aborted},
          dropped => $_->{dropped},
        } } @{$roles});
}

sub get_admin_game_list {
    my ($dbh, $user, $mode, $status) = @_;

    my $games = $dbh->selectall_arrayref(
        "select id, 'admin' as faction, write_id, finished, (extract(epoch from now() - game.last_update)) as time_since_update, (select faction from game_role as gr2 where gr2.game = game.id and action_required limit 1) as waiting_for, round, aborted from game where admin_user=? and (finished = ? or (finished and last_update > now() - interval '2 days'))",
        { Slice => {} },
        $user, $status);
    sorted_user_games (map {
        { id => $_->{id},
          role => 'admin',
          link => ($mode eq 'other-user' ? "/game/$_->{game}" : role_link($dbh, $_)),
          finished => $_->{finished} ? 1 : 0,
          action_required => 0,
          seconds_since_update => $_->{time_since_update},
          vp => '',
          rank => '',
          waiting_for => $_->{waiting_for},
          round => $_->{round},
          aborted => $_->{aborted},
        } } @{$games});
}

sub get_user_game_list {
    my ($dbh, $user, $mode, $status, $admin) = @_;

    if ($admin) {
        get_admin_game_list $dbh, $user, $mode, $status;
    } else {
        get_player_game_list $dbh, $user, $mode, $status;
    }
}

sub abort_game {
    my ($dbh, $write_id) = @_;

    $dbh->do("update game set aborted=true, finished=true where write_id=?",
             {},
             $write_id);
}

sub unabort_game {
    my ($dbh, $write_id) = @_;

    $dbh->do("update game set aborted=false, finished=false where write_id=?",
             {},
             $write_id);
}

1;
