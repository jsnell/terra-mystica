#!/usr/bin/perl -wl

package terra_mystica;

use strict;

use List::Util qw(min max sum);
use JSON;
use POSIX;
use File::Basename qw(dirname);
use File::Slurp;

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;
use DB::Game;

my $ratings = decode_json read_file "www-prod/data/ratings.json";
my $player_ratings = $ratings->{players};

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

my %stats = ();

sub bucket_key {
    my ($game, $faction) = @_;

    my $faction_count = scalar keys %{$game->{factions}};

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

    my %key = (
        player_count => $faction_count,
        start_position => $start_position,
        faction => $faction->{faction},
        final_scoring => ($game->{non_standard} ? 'expansion' : 'original'),
        min_rating => $game->{min_rating},
        map => $game->{base_map}
    );

    return encode_json \%key;
}

sub record_stats {
    my ($res, $stat, $pos, $faction_count, $win_vp, $winner_count, $average_vp) = @_;

    $stat->{count}++;

    if ($_->{vp} == $win_vp) {
        $stat->{wins} += 1 / $winner_count;
    }
    if ($_->{vp} > ($stat->{high_score}{vp} // 0)) {
        $stat->{high_score} = {
            vp => $_->{vp},
            game => $res->{id},
            player => $_->{username},
            time => $_->{last_update},
        }
    }
    $stat->{average_vp} += $_->{vp};
    $stat->{average_winner_vp} += $win_vp;
    $stat->{average_margin} += ($_->{vp} - $average_vp);
    $stat->{average_position} += $pos;    
    $stat->{expected_wins} += 1/$faction_count;
}

sub handle_game {
    my $res = shift;

    my $pos = 0;
    my $win_vp = 0;
    my $winner_count = 0;
    my $faction_count = keys %{$res->{factions}};

    return if $faction_count < 2;

    my %player_ids = ();
    my $min_rating = 10000;

    for (values %{$res->{factions}}) {
        my $r = $player_ratings->{$_->{username} // ''}{score} // 0;
        $min_rating = min $r, $min_rating;

        next if !$_->{id_hash};
        # Filter out games with same player playing multiple factions
        if ($player_ids{$_->{id_hash}}++) {
            return;
        }
    }    
    if ($min_rating >= 1250) {
        $res->{min_rating} = 1250;
    } elsif ($min_rating >= 1000) {
        $res->{min_rating} = 1000;
    } else {
        $res->{min_rating} = 0;        
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

    my $order = 1;
    for (sort { $a->{start_order} <=> $b->{start_order} } values %{$res->{factions}}) {
        $_->{start_order} = $order++;
    }

    my $vp_sum = sum map { $_->{vp} } values %{$res->{factions}};

    for (sort { $b->{vp} <=> $a->{vp} } values %{$res->{factions}}) {
        $pos++;
        if ($pos == 1) {
            $win_vp = $_->{vp};
            $winner_count = grep {
                $_->{vp} == $win_vp
            } values %{$res->{factions}};
        }

        my $bucket_key = bucket_key $res, $_;
        my $stat = $stats{$bucket_key} ||= {
            wins => 0,
        };

        record_stats($res, $stat, $pos, $faction_count,
                     $win_vp, $winner_count,
                     # Average opponent vp.
                     ($vp_sum - $_->{vp}) / ($faction_count - 1));
    }
}

my $dbh = get_db_connection;
my %results = get_finished_game_results $dbh, '', (id_pattern => $ARGV[0]);
my %games = ();

my @exclude_factions = qw(riverwalkers
                          riverwalkers_v4
                          shapeshifters
                          shapeshifters_v2
                          shapeshifters_v3
                          shapeshifters_v4);

for (@{$results{results}}) {
    next if $_->{dropped};
    next if !defined $_->{vp};

    my @ss_opt = map /variable_(v2|v3|v4|v5)/g, @{$_->{options}};
    if (@ss_opt and $_->{faction} eq 'shapeshifters') {
        $_->{faction} = "shapeshifters_@{ss_opt}";
    }

    my @rw_opt = map /variable_(v4|v5)/g, @{$_->{options}};
    if (@rw_opt and $_->{faction} eq 'riverwalkers') {
        $_->{faction} = "riverwalkers_@{rw_opt}";
    }

    $games{$_->{game}}{factions}{$_->{faction}} = $_;
    $games{$_->{game}}{id} = $_->{game};
    $games{$_->{game}}{non_standard} = $_->{non_standard};
    $games{$_->{game}}{base_map} = ($_->{base_map} || '126fe960806d587c78546b30f1a90853b1ada468');
    $games{$_->{game}}{last_update} = $_->{last_update};
}

GAMES: for (sort { $a->{last_update} cmp $b->{last_update} } values %games) {
    for my $f (@exclude_factions) {
        if (exists $_->{factions}{$f}) {
            next GAMES;
        }
    }

    handle_game $_;
}

print_json [ map { [ decode_json($_), $stats{$_} ] } keys %stats ]
