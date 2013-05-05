#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use JSON;
use POSIX;
use File::Basename qw(dirname);

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use results;

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

my %stats = ();

sub handle_game {
    my $res = shift;

    my $pos = 0;
    my $win_vp = 0;
    my $faction_count = keys %{$res->{factions}};

    return if $faction_count < 3;

    for (sort { $b->{vp} <=> $a->{vp} } values %{$res->{factions}}) {
        $pos++;
        my $stat = ($stats{factions}{$_->{faction}} ||= {
            wins => 0,
            games_won => [],
        });
        $stat->{count}++;
        if ($pos == 1) {
            $win_vp = $_->{vp}
        }
        if ($_->{vp} == $win_vp) {
            my $win_count = grep {
                $_->{vp} == $win_vp
            } values %{$res->{factions}};
            $stat->{wins} += 1 / $win_count;
            push @{$stat->{games_won}}, $res->{id};
        }
        if ($_->{vp} > ($stat->{high_score}{$faction_count}{vp} // 0)) {
            $stat->{high_score}{$faction_count} = {
                vp => $_->{vp},
                game => $res->{id},
            }
        }
        $stat->{average_vp} += $_->{vp};
        $stat->{average_winner_vp} += $win_vp;
        $stat->{average_position} += $pos;
    }
}

my %results = get_finished_game_results '';
my %games = ();

for (@{$results{results}}) {
    $games{$_->{game}}{factions}{$_->{faction}} = $_;
    $games{$_->{game}}{id} = $_->{game};
}

for (values %games) {
    handle_game $_;
}

for my $stat (values %{$stats{factions}}) {
    $stat->{win_rate} = int(100 * $stat->{wins} / $stat->{count});
    $stat->{average_loss_vp} = sprintf "%5.2f", ($stat->{average_winner_vp} - $stat->{average_vp}) / $stat->{count};
    $stat->{average_vp} = sprintf "%5.2f", $stat->{average_vp} / $stat->{count};
    $stat->{average_position} = sprintf "%5.2f", $stat->{average_position} / $stat->{count};

    delete $stat->{average_winner_vp};
}

$stats{timestamp} = POSIX::strftime "%Y-%m-%d %H:%M UTC", gmtime time;

print_json { %stats };
