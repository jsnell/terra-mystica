#!/usr/bin/perl -w

package DB::UserInfo;
use Exporter::Easy (
    EXPORT => [qw(fetch_user_metadata fetch_user_stats fetch_user_opponents)]
    );

use strict;

sub fetch_user_metadata {
    my ($dbh, $username) = @_;

    my ($rows) =
        $dbh->selectall_arrayref("select username, displayname, rating from player left join player_ratings on player.username=player_ratings.player where username=?;",
                                 { Slice => {} },
                                 $username);

    $rows->[0];
}

sub fetch_user_stats {
    my ($dbh, $username) = @_;

    my ($rows) =
        $dbh->selectall_arrayref("select faction, max(vp) as max_vp, sum(vp)/count(*) as mean_vp, count(*), count(case when rank = 1 then true end) as wins, count(case when rank = 1 then true end)*100/count(*) as win_percentage, array_agg(rank) as ranks from game_role where email in (select address from email where player=?) and faction != 'admin' and game in (select id from game where finished and not aborted and not exclude_from_stats) group by faction order by win_percentage desc",
                                 { Slice => {} },
                                 $username);
    $rows;
}

sub fetch_user_opponents {
    my ($dbh, $username) = @_;

    my %res = ();

    my ($games) =
        $dbh->selectall_arrayref("select game, array_agg(email.player) as players, array_agg(rank) as ranks from game_role inner join email on game_role.email=email.address where game in (select game from game_role where email in (select address from email where player=?) and faction != 'admin' and game in (select id from game where finished and not aborted and not exclude_from_stats)) and faction != 'admin' group by game",
                                 { Slice => {} },
                                 $username);

    for my $game (@{$games}) {
        my %ranks = ();
        while (@{$game->{ranks}}) {
            my $player = pop @{$game->{players}};

            next if !defined $player;

            my $rank = pop @{$game->{ranks}};
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
