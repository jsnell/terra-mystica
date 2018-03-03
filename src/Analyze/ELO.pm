#!/usr/bin/perl -wl

package Analyze::ELO;
use Exporter::Easy (EXPORT => ['compute_elo', 'pprint_elo_results']);

use strict;

use List::Util qw(shuffle sum);
use Method::Signatures::Simple;
use JSON;

### Tunable parameters

my %default_settings = (
    # How many times the full set of games is scored.
    iters => 3,
    # Later iterations have exponentially less effect on scores. This controls
    # the exponent.
    iter_decay_exponent => 2,
    # For any pairwise match, the 2 players combined will bet this amount of
    # rating points.
    pot_size => 16,
    # Any pairwise matches will only be included if both players have played
    # at least this many games in total. Players with a smaller number of
    # played games will have a "shadow rating" computed for them, but will
    # not affect the ratings of any other entity.
    min_games => 5,
    # Only return the results for players who have played at least in this
    # many games.
    min_output_games => 5,
    faction_weigth => 1,
    # If true, players who drop out of a game are completely ignored in
    # the rating calculation (rather than being ranked based on the VP
    # they finished with). Only for running prediction experiments, must
    # always remain false in production use.
    ignore_dropped => 0,
);

sub init_players {
    my $players = shift;
    for (values %{$players}) {
        $_->{score} = 1000;
    }
}

sub init_factions {
    my ($factions, $factions_by_map) = @_;

    for my $fkey (keys %{$factions}) {
        my $record = $factions->{$fkey};
        ($record->{name}, $record->{base_map}) = split / /, $fkey;
        $record->{score} = 1000;
        $factions_by_map->{$record->{base_map}}{$fkey} = $record;
    }
}

sub iterate_results {
    my ($matches, $players, $factions, $iter, $settings) = @_;
    my @shuffled = sort {
        $a->{last_update} cmp $b->{last_update};
    } @{$matches};

    my $pot = $settings->{pot_size} / $iter ** $settings->{iter_decay_exponent};
    for my $res (@shuffled) {
        my $p1 = $players->{$res->{a}{id_hash}};
        my $p2 = $players->{$res->{b}{id_hash}};
        my $fw = $settings->{faction_weigth};

        if ($res->{a}{dropped} or $res->{b}{dropped}) {
            if ($settings->{ignore_dropped}) {
                next;
            } else {
                $fw = 0;
            }
        }

        my $f1 = $factions->{$res->{a}{fkey}};
        my $f2 = $factions->{$res->{b}{fkey}};

        my $q1 = $f1->{score} // 1000;
        my $q2 = $f2->{score} // 1000;
        
        my $p1_score = $p1->{score} + $q1 * $fw;
        my $p2_score = $p2->{score} + $q2 * $fw;
        my $diff = $p1_score - $p2_score;

        my $ep1 = 1 / (1 + 10**(-$diff / 400));
        my $ep2 = 1 / (1 + 10**($diff / 400));

        my ($ap1, $ap2);

        my $a_vp = $res->{a}{vp};
        my $b_vp = $res->{b}{vp};

        if ($a_vp == $b_vp) {
            ($ap1, $ap2) = (0.5, 0.5);
        } elsif ($a_vp > $b_vp) {
            ($ap1, $ap2) = (1, 0);
        } else {
            ($ap1, $ap2) = (0, 1);
        }

        my $p1_delta = $pot * ($ap1 - $ep1);
        my $p2_delta = $pot * ($ap2 - $ep2);
        my $count = ($p1->{games} >= $settings->{min_games}) + ($p2->{games} >= $settings->{min_games});

        # Upgrade the rating of a player either if both players are new,
        # or if the opponent is not new. This has the effect that new
        # players will have a "shadow rating" computed for them, but will
        # not affect the ratings of opponents or factions.
        if ($p2->{games} >= $settings->{min_games} or !$count) {
            $p1->{score} += $p1_delta;
        }
        if ($p1->{games} >= $settings->{min_games} or !$count) {
            $p2->{score} += $p2_delta;
        }
        next if $count != 2;

        $p1->{faction_breakdown}{$res->{a}{faction}}{score} += $p1_delta;
        $p2->{faction_breakdown}{$res->{b}{faction}}{score} += $p2_delta;

        $f1->{score} += $pot * ($ap1 - $ep1) * $fw;
        $f2->{score} += $pot * ($ap2 - $ep2) * $fw;

        $p1->{faction_plays}{$res->{a}{faction}}{$res->{id}} = 1;
        $p2->{faction_plays}{$res->{b}{faction}}{$res->{id}} = 1;
    }
}

sub compute_elo {
    my ($rating_data, $settings) = @_;
    my %players = %{$rating_data->{players}};
    my %factions = %{$rating_data->{factions}};
    my %factions_by_map = ();
    my @matches = @{$rating_data->{results}};

    $settings ||= {};

    for my $key (keys %default_settings) {
        if (!defined $settings->{$key}) {
            $settings->{$key} = $default_settings{$key};
        }
    }

    init_players \%players;
    init_factions \%factions, \%factions_by_map;

    for (1..$settings->{iters}) {
        iterate_results \@matches, \%players, \%factions, $_, $settings;
    }

    return {
        players => {
            map {
                for my $faction (keys %{$_->{faction_plays}}) {
                    $_->{faction_breakdown}{$faction}{count} = scalar keys %{$_->{faction_plays}{$faction}};
                }
                delete $_->{faction_plays};
                ($_->{username} => $_);
            } grep {
                $_->{games} >= $settings->{min_output_games};
            } grep {
                $_->{username} !~ /unregistered-/;
            } values %players,
        },
        factions => \%factions,
        factions_by_map => \%factions_by_map,
    };
}

sub pprint_elo_results {
    my ($elo, $settings) = @_;
    my %factions = %{$elo->{factions}};
    my %players = %{$elo->{players}};

    print "-- Factions";

    for my $p (sort { $b->{score} <=> $a->{score} } values %factions) {
        printf "%-5d [%-3d] %s\n", $p->{score}, $p->{games}, $p->{name};
    }

    print "-- Players";

    for my $p (sort { $b->{score} <=> $a->{score} } values %players) {
        next if $p->{games} < $settings->{min_games};
        printf "%-5d [%-3d] %s\n", $p->{score}, $p->{games}, $p->{username};
    }
}

1;
