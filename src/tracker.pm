#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use List::Util qw(sum max min);

use vars qw($round @ledger @action_required %leech);

use commands;
use cults;
use factions;
use map;
use resources;
use scoring;
use tiles;
use towns;

our %leech = ();
our @action_required = ();
our @ledger = ();
our $round = 0;

## 

sub faction_income {
    my $faction_name = shift;
    my $faction = $factions{$faction_name};

    my %total_income = map { $_, 0 } qw(C W P PW);

    my %total_building_income = %total_income;
    my %total_favor_income = %total_income;
    my %total_bonus_income = %total_income;
    my %total_scoring_income = %total_income;

    my %buildings = %{$faction->{buildings}};

    for my $building (values %buildings) {
        if (exists $building->{income}) {
            my %building_income = %{$building->{income}};
            for my $type (keys %building_income) {
                my $delta = $building_income{$type}[$building->{level}];
                if ($delta) {
                    $total_building_income{$type} += $delta;
                }
            }
        }
    }

    for my $tile (keys %{$faction}) {
        if (!$faction->{$tile}) {
            next;
        }

        if ($tile =~ /^(BON|FAV)/) {
            my $tile_income = $tiles{$tile}{income};
            for my $type (keys %{$tile_income}) {
                if ($tile =~ /^BON/ and $faction->{passed}) {
                    $total_bonus_income{$type} += $tile_income->{$type};
                } elsif ($tile =~ /^FAV/) {
                    $total_favor_income{$type} += $tile_income->{$type};
                }
            }
        }
    }

    my $scoring = current_score_tile;
    if ($scoring and $round != 6) {
        my %scoring_income = %{$scoring->{income}};

        my $mul = int($faction->{$scoring->{cult}} / $scoring->{req});
        for my $type (keys %scoring_income) {
            $total_scoring_income{$type} += $scoring_income{$type} * $mul;
        }        
    }

    $faction->{income_breakdown} = {};

    $faction->{income_breakdown}{bonus} = \%total_bonus_income;
    $faction->{income_breakdown}{scoring} = \%total_scoring_income;
    $faction->{income_breakdown}{favors} = \%total_favor_income;
    $faction->{income_breakdown}{buildings} = \%total_building_income;

    for my $subincome (values %{$faction->{income_breakdown}}) {
        my $total = 0;
        for my $type (keys %{$subincome}) {
            $total_income{$type} += $subincome->{$type};
            if (grep { $type eq $_} qw(C W P PW)) {
                $total += $subincome->{$type};
            }
        }
        if (!$total) {
            $subincome = undef;
        }
    }

    return %total_income;
}

my %building_aliases = (
    DWELLING => 'D',
    'TRADING POST' => 'TP',
    TEMPLE => 'TE',
    STRONGHOLD => 'SH',
    SANCTUARY => 'SA',
    );

sub alias_building {
    my $type = shift;

    return $building_aliases{$type} // $type;
}

sub note_leech {
    my ($where, $from_faction) = @_;
    my $color = $from_faction->{color};
    my %this_leech = ();

    return if !$round;

    for my $adjacent (keys %{$map{$where}{adjacent}}) {
        my $map_color = $map{$adjacent}{color};
        if ($map{$adjacent}{building} and
            $map_color ne $color) {
            $this_leech{$map_color} +=
                $building_strength{$map{$adjacent}{building}};
            $this_leech{$map_color} = min $this_leech{$map_color}, 5;
        }
    }

    for my $faction_name (factions_in_order_from $from_faction->{name}) {
        my $faction = $factions{$faction_name};
        my $color = $faction->{color}; 
        next if !$this_leech{$color};
        my $amount = $this_leech{$color};

        push @action_required, { type => 'leech',
                                 from_faction => $from_faction->{name},
                                 amount => $amount, 
                                 faction => $faction->{name} };
    }

    for (keys %this_leech) {
	$leech{$_} += $this_leech{$_};
    }
}

sub take_income_for_faction {
    my $faction_name = shift;
    my $faction = $factions{$faction_name};
    die "Taking income twice for $faction_name\n" if
        $faction->{income_taken};

    if ($round == 0) {
        $faction->{passed} = 1;
    }

    my %income = faction_income $faction_name;
    gain $faction, \%income;
        
    $faction->{income_taken} = 1;

    if ($faction->{SHOVEL}) {
        push @action_required, { type => 'transform',
                                 amount => $faction->{SHOVEL}, 
                                 faction => $faction->{name} };
    }
}

sub finalize {
    for my $faction (@factions) {
        $factions{$faction}{income} = { faction_income $faction };
    }
        
    if ($round > 0) {
        for (0..($round-2)) {
            $tiles{$score_tiles[$_]}->{old} = 1;
        }
        
        current_score_tile->{active} = 1;
    }
    
    if (@score_tiles) {
        $tiles{$score_tiles[-1]}->{income_display} = '';
    }

    for my $hex (values %map) {
        delete $hex->{adjacent};
        delete $hex->{range};
    }
    
    for my $faction (@factions) {
        delete $factions{$faction}{locations};
        delete $factions{$faction}{teleport};
    }

    for my $key (keys %cults) {
        $map{$key} = $cults{$key};
    }

    for my $key (keys %bonus_coins) {
        $map{$key} = $bonus_coins{$key};
        $tiles{$key}{bonus_coins} = $bonus_coins{$key};
    }
}

sub evaluate_game {
    my $row = 1;
    my @error = ();

    for (@_) {
        eval { handle_row $_ };
        if ($@) {
            chomp;
            push @error, "Error on line $row [$_]:";
            push @error, "$@\n";
            last;
        }
        $row++;
    }

    finalize;

    return {
        order => \@factions,
        map => \%map,
        factions => \%factions,
        pool => \%pool,
        bridges => \@bridges,
        ledger => \@ledger,
        error => \@error,
        towns => { map({$_, $tiles{$_}} grep { /^TW/ } keys %tiles ) },
        score_tiles => [ map({$tiles{$_}} @score_tiles ) ],
        bonus_tiles => { map({$_, $tiles{$_}} grep { /^BON/ } keys %tiles ) },
        favors => { map({$_, $tiles{$_}} grep { /^FAV/ } keys %tiles ) },
        action_required => \@action_required,
        cults => \%cults,
    }

}
