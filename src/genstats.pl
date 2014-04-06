#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use JSON;
use POSIX;
use File::Basename qw(dirname);

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;
use DB::Game;

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

my %stats = ();

sub record_stats {
    my ($res, $stat, $pos, $faction_count, $win_vp, $winner_count) = @_;

    $stat->{count}++;

    if ($_->{vp} == $win_vp) {
        $stat->{wins} += 1 / $winner_count;
        push @{$stat->{games_won}}, $res->{id};
    }
    my $standard = $res->{non_standard} ? 'non-standard' : 'standard';
    if ($_->{vp} > ($stat->{high_score}{$standard}{$faction_count}{vp} // 0)) {
        $stat->{high_score}{$standard}{$faction_count} = {
            vp => $_->{vp},
            game => $res->{id},
            player => $_->{username},
        }
    }
    $stat->{average_vp} += $_->{vp};
    $stat->{average_winner_vp} += $win_vp;
    $stat->{average_position} += $pos;    
    $stat->{expected_wins} += 1/$faction_count;
}

sub handle_game {
    my $res = shift;

    my $pos = 0;
    my $win_vp = 0;
    my $winner_count = 0;
    my $faction_count = keys %{$res->{factions}};

    return if $faction_count < 3;

    my %player_ids = ();

    for (values %{$res->{factions}}) {
        next if !$_->{id_hash};
        # Filter out games with same player playing multiple factions
        if ($player_ids{$_->{id_hash}}++) {
            return;
        }
    }

    # Filter out games with no players with an email address
    if (!keys %player_ids) {
        # Whitelist some old PBF games, etc.
        my %whitelist = map { ($_, 1 ) } qw(
            0627puyo
            10
            17
            19
            20
            23
            24
            26
            27
            5
            8
            9
            BlaGame11
            BlaGame8
            IBGPBF5
            Noerrorpls
            gamecepet
            gareth2
            nyobagame
            pbc1
            pbc2
            pbc3
            skelly1
            skelly1a
            skelly1b
            skelly1c
            skelly1d
            skelly1e
            skelly1f
            verandi1
            verandi2
        );
        if (!$whitelist{$res->{id}}) {
            return;
        }
    }

    for (sort { $b->{vp} <=> $a->{vp} } values %{$res->{factions}}) {
        $pos++;
        if ($pos == 1) {
            $win_vp = $_->{vp};
            $winner_count = grep {
                $_->{vp} == $win_vp
            } values %{$res->{factions}};
        }

        my $faction_stat = ($stats{factions}{$_->{faction}} ||= {
            wins => 0,
            games_won => [],
        });

        my $start_position = ($_->{start_order} - 1) / ($faction_count - 1);
        if ($start_position == 0) {
            $start_position = 'first';
        } elsif ($start_position == 1) {
            $start_position = 'last';
        } elsif ($start_position == 0.5) {
            $start_position = 'middle';
        } elsif ($start_position < 0.5) {
            $start_position = 'second';
        } else {
            $start_position = 'second-to-last';
        }
        my $position_stat = ($stats{"positions-${faction_count}p"}{$start_position} ||= {
            wins => 0,
            games_won => [],
        });

        for my $stat (($faction_stat, $position_stat)) {
            record_stats($res, $stat, $pos, $faction_count,
                         $win_vp, $winner_count);
        }
    }
}

my $dbh = get_db_connection;
my %results = get_finished_game_results $dbh, '', $ARGV[0];
my %games = ();

for (@{$results{results}}) {
    $games{$_->{game}}{factions}{$_->{faction}} = $_;
    $games{$_->{game}}{id} = $_->{game};
    $games{$_->{game}}{non_standard} = $_->{non_standard};
}

for (values %games) {
    handle_game $_;
}

for my $stat (values %{$stats{factions}}) {
    $stat->{win_rate} = int(100 * $stat->{wins} / $stat->{count});
    $stat->{expected_win_rate} = int(100 * $stat->{expected_wins} / $stat->{count});
    $stat->{average_loss_vp} = sprintf "%5.2f", ($stat->{average_winner_vp} - $stat->{average_vp}) / $stat->{count};
    $stat->{average_vp} = sprintf "%5.2f", $stat->{average_vp} / $stat->{count};
    $stat->{average_position} = sprintf "%5.2f", $stat->{average_position} / $stat->{count};

    $stat->{wins} = 0 + sprintf "%5.2f", $stat->{wins};

    delete $stat->{average_winner_vp};
}

for (3..5) {
    for my $stat (values %{$stats{"positions-${_}p"}}) {
        next if !$stat->{count};
        $stat->{win_rate} = int(100 * $stat->{wins} / $stat->{count});
        $stat->{expected_win_rate} = int(100 * $stat->{expected_wins} / $stat->{count});
        $stat->{average_loss_vp} = sprintf "%5.2f", ($stat->{average_winner_vp} - $stat->{average_vp}) / $stat->{count};
        $stat->{average_vp} = sprintf "%5.2f", $stat->{average_vp} / $stat->{count};
        $stat->{average_position} = sprintf "%5.2f", $stat->{average_position} / $stat->{count};
        
        delete $stat->{average_winner_vp};
    }
}

$stats{timestamp} = POSIX::strftime "%Y-%m-%d %H:%M UTC", gmtime time;

print_json { %stats };
