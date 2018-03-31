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
                  get_game_list_by_pattern
                  abort_game
                  unabort_game
                )]
    );

use strict;

use DBI;
use Digest::SHA qw(sha1_hex);

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
        $dbh->selectall_hashref("select game_role.faction, player.username, email.address as email, player.displayname from game_role inner join email on email.player=game_role.faction_player inner join player on player.username=game_role.faction_player where game_role.game=?",
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
        $dbh->selectall_arrayref("select extract(epoch from now() - last_update) as time_since_update, game.description, finished, aborted, game_options, player_count, wanted_player_count, base_map as map_variant, game_options.deadline_hours, game_options.minimum_rating, game_options.maximum_rating, game_options.chess_clock_hours_initial, game_options.chess_clock_hours_per_round, game_options.chess_clock_grace_period, admin_user, game.exclude_from_stats from game left join game_options on game.id=game_options.game where game.id=?",
                                 { Slice => {} },
                                 $id);

    my $res = $rows->[0];

    if ($res->{map_variant}) {        
        my ($map_str, $vp_variant) = $dbh->selectrow_array("select terrain, vp_variant from map_variant where id=?", {}, $res->{map_variant});
        $res->{base_map} = [ split /\s+/, $map_str ];
        $res->{vp_variant} = $vp_variant;
    }

    $res->{active_times} = 
        $dbh->selectall_arrayref("select * from game_active_time where game=?",
                                 { Slice => {} },
                                 $id);

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
    my ($dbh, $secret, %params) = @_;

    my %res = ( error => '', results => [] );

    $dbh->do('begin');

    # Filter out games by some dicks who are getting their kicks by
    # distorting the stats with ridiculous games.
    $dbh->do("update game set exclude_from_stats=true where admin_user in (select player from blacklist) and not exclude_from_stats");

    $params{id_pattern} ||= '%';
    if ($params{year} and $params{month}) {
        if ($params{day}) {
            $params{range_end} = '1 day';
        } else {
            $params{day} = '01';
            $params{range_end} = '1 month';
        }
        $params{range_start} = "$params{year}-$params{month}-$params{day}";
    } else {
        $params{range_start} = "1970-01-01";
        $params{range_end} = "100 years";
    }

    my $rows = $dbh->selectall_arrayref(
        "select game, faction, vp, rank, start_order, faction_player as username, game.player_count, game.last_update, game.non_standard, game.base_map, game_role.dropped, game.game_options as options, game.exclude_from_stats from game_role left join game on game=game.id where game.finished and game.round=6 and not game.aborted and game.id like ? and game.last_update between ? and date(?) + ?::interval",
        { Slice => {} },
        $params{id_pattern},
        $params{range_start},
        $params{range_start},
        $params{range_end});

    if (!$rows) {
        $res{error} = "db error";
    } else {
        for my $row (@{$rows}) {
            next if $row->{exclude_from_stats} and !$params{include_unranked};
            $row->{id_hash} = ($row->{username} ? sha1_hex($row->{username} . $secret) : undef);
            push @{$res{results}}, $row;
        }
    }

    $dbh->do('commit');

    %res;
}

sub get_open_game_list {
    my ($dbh) = @_;

    my $games = $dbh->selectall_arrayref(
        "select game.id, game.player_count, game.wanted_player_count, game.description, array(select player from game_player where game_player.game=game.id) as players, game.game_options, game_options.minimum_rating, game_options.maximum_rating, game_options.deadline_hours, game_options.chess_clock_hours_initial, game_options.chess_clock_hours_per_round, game_options.chess_clock_grace_period, game.base_map as map_variant from game left join game_options on game.id=game_options.game where game.wanted_player_count is not null and game.player_count != game.wanted_player_count and not game.finished",
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
        "/faction/$record->{game}/$record->{faction}/"
        # edit_link_for_faction $dbh, $record->{write_id}, $record->{faction};
    }
}

sub get_player_game_list {
    my ($dbh, $user, $mode, $status) = @_;

    my $roles = $dbh->selectall_arrayref(
        "select gr1.game, gr1.faction, game.write_id, game.finished, action_required, (extract(epoch from now() - game.last_update)) as time_since_update, vp, rank, (select faction from game_role as gr2 where gr2.game = gr1.game and action_required limit 1) as waiting_for, leech_required, game.round, (select count(*) from chat_message where game=game.id and posted_at > (select coalesce((select last_read from chat_read where game=chat_message.game and player=?), '2012-01-01'))) as unread_chat, game.aborted, gr1.dropped, game_options.deadline_hours from game_role as gr1 left join game on gr1.game=game.id left join game_options on gr1.game=game_options.game where faction_player=? and (game.finished = ? or (game.finished and last_update > now() - interval '2 days'))",
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
          deadline_hours => $_->{deadline_hours},
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

sub get_game_list_by_pattern {
    my ($dbh, $ids) = @_;

    my $res = $dbh->selectall_arrayref(
        "select id, finished, aborted, round, turn, array_agg(game_role.faction) as factions, array_agg(game_role.faction_player) as usernames, array_agg(game_role.rank) as ranks, array_agg(game_role.vp) as vps, array_agg(game_role.dropped) as dropped, (extract(epoch from now() - game.last_update)) as seconds_since_update, array_agg(game_active_time.active_seconds_12h) as time_taken_seconds from game join game_role on game.id=game_role.game left join game_active_time on game_active_time.game=game.id and game_active_time.player=game_role.faction_player where id like ? group by id, finished, aborted, last_update, round order by id limit 2000",
        { Slice => {} },
        $ids);

    $res;
}

sub abort_game {
    my ($dbh, $write_id) = @_;

    $dbh->do("update game set aborted=true, finished=true where write_id=?",
             {},
             $write_id);
}

sub unabort_game {
    my ($dbh, $write_id) = @_;

    $dbh->do("update game set aborted=false, finished=false, last_update=now() where write_id=?",
             {},
             $write_id);
}

1;
