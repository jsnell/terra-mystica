#!/usr/bin/perl -w

use strict;

package DB::Game;

use DBI;
use Exporter::Easy (
    EXPORT => [qw(game_exists
                  get_game_content
                  get_game_commands
                  get_game_factions
                  get_game_players
                  get_game_metadata
                  begin_game_transaction
                  finish_game_transaction
                  get_chat_count)]
    );

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
        $dbh->selectall_arrayref("select extract(epoch from now() - last_update) as time_since_update, description from game where id=?",
                                 { Slice => {} },
                                 $id);

    $rows->[0];
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

1;
