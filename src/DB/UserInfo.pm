#!/usr/bin/perl -w

package DB::UserInfo;
use Exporter::Easy (
    EXPORT => [qw(fetch_user_metadata fetch_user_stats fetch_user_opponents)]
    );

use strict;

sub fetch_user_metadata {
    my ($dbh, $username) = @_;

    my ($metadata) =
        $dbh->selectall_arrayref("select username, displayname, rating from player left join player_ratings on player.username=player_ratings.player where username=?",
                                 { Slice => {} },
                                 $username);

    my ($games) =
        $dbh->selectall_arrayref("select game.id, game_role.dropped, game.finished, game.aborted from game_role left join game on game.id=game_role.game  where game_role.faction_player=?",
                                 { Slice => {} },
                                 $username);

    my $metadata = $metadata->[0];

    my %handled = ();
    for my $game (@{$games}) {
        next if $handled{$game->{id}}++;

        if ($game->{dropped}) {
            $metadata->{dropped}++;
        } elsif ($game->{aborted}) {
            $metadata->{aborted}++;
        } elsif ($game->{finished}) {
            $metadata->{finished}++;
        } else {
            $metadata->{running}++;
        }
        $metadata->{total_games}++;
    }

    $metadata;
}

sub fetch_user_stats {
    my ($dbh, $username) = @_;

    my ($rows) =
        $dbh->selectall_arrayref("select faction, max(vp) as max_vp, sum(vp)/count(*) as mean_vp, count(*), count(case when rank = 1 then true end) as wins, count(case when rank = 1 then true end)*100/count(*) as win_percentage, array_agg(rank) as ranks from game_role where faction_player=? and game in (select id from game where finished and not aborted and not exclude_from_stats) group by faction order by win_percentage desc",
                                 { Slice => {} },
                                 $username);
    $rows;
}

sub fetch_user_opponents {
    my ($dbh, $username) = @_;

    my %res = ();

    my ($games) =
        $dbh->selectall_arrayref("select game, array_agg(faction_player) as players, array_agg(rank) as ranks from game_role where game in (select game from game_role where faction_player=? and game in (select id from game where finished and not aborted and not exclude_from_stats)) group by game",
                                 { Slice => {} },
                                 $username);

    for my $game (@{$games}) {
        my %ranks = ();
        
        while (@{$game->{ranks}}) {
            my $player = pop @{$game->{players}};
            my $rank = pop @{$game->{ranks}};

            next if !defined $player;

            $ranks{$player} = $rank;
        }
        for my $opponent (keys %ranks) {
            next if $opponent eq $username;

            $res{$opponent}{username} = $opponent;
            $res{$opponent}{count}++;
            if ($ranks{$username} > $ranks{$opponent}) {
                $res{$opponent}{opponent_better}++;
            } elsif ($ranks{$username} < $ranks{$opponent}) {
                $res{$opponent}{player_better}++;
            } else {
                $res{$opponent}{draw}++;
            }
        }
    }

    my @res = sort { $b->{count} <=> $a->{count} } values %res;

    [ @res ];
}

1;
