package terra_mystica;

use strict;

use vars qw(@score_tiles);
our @score_tiles = ();

use cults;
use tiles;

sub adjust_resource;
sub command;
sub compute_network_size;

sub current_score_tile {
    if ($round > 0) {
        return $tiles{$score_tiles[$round - 1]};
    }
}

sub maybe_score_current_score_tile {
    my ($faction, $type) = @_;

    my $scoring = current_score_tile;
    if ($scoring) {
        my $gain = $scoring->{vp}{$type};
        if ($gain) {
            adjust_resource $faction, 'VP', $gain;
        }
    }
}

sub maybe_score_favor_tile {
    my ($faction, $type) = @_;

    for my $tile (keys %{$faction}) {
        next if !$faction->{$tile};
        if ($tile =~ /^FAV/) {
            my $scoring = $tiles{$tile}{vp};
            if ($scoring) {
                my $gain = $scoring->{$type};
                if ($gain) {
                    adjust_resource $faction, 'VP', $gain;
                }
            }
        }
    }
}

sub score_type_rankings {
    my ($type, @scores) = @_;

    my @levels = sort { $a <=> $b } map { $factions{$_}{$type} // 0} keys %factions;
    my %scores = ();
    my %count = ();
    $count{$_}++ for @levels;

    $scores{pop @levels} += $_ for @scores;
        
    for my $faction_name (@factions) {
        my $level = $factions{$faction_name}{$type};
        next if !$level or !defined $scores{$level};
        my $vp = $scores{$level} / $count{$level};
        if ($vp) {
            handle_row("$faction_name: +${vp}vp");
        }
    }
}

sub score_final_cults {
    for my $cult (@cults) {
        push @ledger, { comment => "Scoring $cult cult" };
        score_type_rankings $cult, 8, 4, 2;
    }
}

sub score_final_networks {
    compute_network_size $factions{$_} for @factions;
    push @ledger, { comment => "Scoring largest network" };
    score_type_rankings 'network', 18, 12, 6;
}

sub score_final_resources_for_faction {
    my $faction_name = shift;
    my $faction = $factions{$faction_name};

    for (1..($faction->{P3})) {
        command $faction_name, "convert 1pw to 1c";
    }

    for (1..($faction->{P})) {
        command $faction_name, "convert 1p to 1c";
    }

    for (1..($faction->{W})) {
        command $faction_name, "convert 1w to 1c";
    }

    my $rate = $faction->{exchange_rates}{C}{VP} // 3;
    my $vp = int($faction->{C} / $rate);
    my $c = $vp * $rate;
    if ($vp) {
        command $faction_name, "convert ${c}C to ${vp}VP";
    }
}

sub score_final_resources {
    push @ledger, { comment => "Converting resources to VPs" };

    for (@factions) {
        handle_row("$_: score_resources");
    }
}

1;

