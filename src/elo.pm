#!/usr/bin/perl -wl

use strict;
use List::Util qw(shuffle sum);
use JSON;

### Tunable parameters

# How many times the full set of games is scored.
my $ITERS = 2;
# Later iterations have exponentially less effect on scores. This controls
# the exponent.
my $ITER_DECAY_EXPONENT = 2;
# For any pairwise match, the 2 players combined will bet this amount of
# rating points.
my $POT_SIZE = 16;
# Any pairwise matches will only be included if both players have played
# at least this many games in total.
my $MIN_GAMES = 5;

sub init_players {
    my $players = shift;
    for (values %{$players}) {
        $_->{score} = 1000;
    }
}

sub init_factions {
    my ($factions) = @_;

    for my $faction_name (keys %{$factions}) {
        $factions->{$faction_name}{name} = $faction_name;
        $factions->{$faction_name}{score} = 1000;
    }
}

sub iterate_results {
    my ($matches, $players, $factions, $iter) = @_;
    my @shuffled = sort {
        $a->{last_update} cmp $b->{last_update};
    } @{$matches};

    my $pot = $POT_SIZE / $iter ** $ITER_DECAY_EXPONENT;

    for my $res (@shuffled) {
        my $p1 = $players->{$res->{a}{id_hash}};
        my $p2 = $players->{$res->{b}{id_hash}};

        next if $p1->{games} < $MIN_GAMES;
        next if $p2->{games} < $MIN_GAMES;

        my $f1 = $factions->{$res->{a}{faction}};
        my $f2 = $factions->{$res->{b}{faction}};

        my $q1 = $f1->{score};
        my $q2 = $f2->{score};
        
        my $p1_score = $p1->{score} + $q1;
        my $p2_score = $p2->{score} + $q2;
        my $diff = $p1_score - $p2_score;

        my $ep1 = 1 / (1 + 10**(-$diff / 400));
        my $ep2 = 1 / (1 + 10**($diff / 400));

        my ($ap1, $ap2);

        if ($res->{a}{vp} == $res->{b}{vp}) {
            ($ap1, $ap2) = (0.5, 0.5);
        } elsif ($res->{a}{vp} > $res->{b}{vp}) {
            ($ap1, $ap2) = (1, 0);
        } else {
            ($ap1, $ap2) = (0, 1);
        }

        $p1->{score} += $pot * ($ap1 - $ep1);
        $p2->{score} += $pot * ($ap2 - $ep2);

        $f1->{score} += $pot * ($ap1 - $ep1);
        $f2->{score} += $pot * ($ap2 - $ep2);
    }
}

sub compute_elo {
    my $rating_data = shift;

    my %players = %{$rating_data->{players}};
    my %factions = %{$rating_data->{factions}};
    my @matches = @{$rating_data->{results}};

    init_players \%players;
    init_factions \%factions;

    for (1..$ITERS) {
        iterate_results \@matches, \%players, \%factions, $_;
    }

    return {
        players => {
            map {
                ($_->{username} => $_);
            } grep {
                $_->{games} >= $MIN_GAMES;
            } grep {
                $_->{username} !~ /unregistered-/;
            } values %players,
        },
        factions => \%factions
    };
}

sub pprint_elo_results {
    my $elo = shift;
    my %factions = %{$elo->{factions}};
    my %players = %{$elo->{players}};

    print "-- Factions";

    for my $p (sort { $b->{score} <=> $a->{score} } values %factions) {
        printf "%-5d [%-3d] %s\n", $p->{score}, $p->{games}, $p->{name};
    }

    print "-- Players";

    for my $p (sort { $b->{score} <=> $a->{score} } values %players) {
        next if $p->{games} < $MIN_GAMES;
        printf "%-5d [%-3d] %s\n", $p->{score}, $p->{games}, $p->{username};
    }
}

1;
