#!/usr/bin/perl -wl

use strict;
use JSON;
use List::Util qw(sum);

my @factions;
my %factions;
my @cults = qw(EARTH FIRE WATER AIR);
my @ledger = ();
my %map = ();
my @error = ();
my @score_tiles = ();
my $round = 0;

my %setups = (
    alchemists => { C => 15, W => 3, P1 => 5, P2 => 7,
                    WATER => 1, FIRE => 1, color => 'black',
                    ship => { 
                        level => 0,
                        advance_cost => { C => 4, P => 1 },
                        advance_gain => [ { VP => 2 },
                                          { VP => 3 },
                                          { VP => 4 } ]
                    },
                    dig => {
                        level => 0,
                        cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                        advance_cost => { W => 2, C => 5, P => 1 },
                        advance_gain => [ { VP => 6 },
                                          { VP => 6 } ]
                    },
                    special => {
                        SHOVEL => { PW => 2 },
                        enable_if => { SH => 0 },
                    },
                    buildings => {
                        D => { cost => { W => 1, C => 2 },
                               income => { W => [ 8, 8, 7, 6, 5, 4, 3, 2, 1 ] } },
                        TP => { cost => { W => 2, C => 3 },
                                income => { C => [ 11, 7, 4, 2, 0 ],
                                            PW => [ 4, 3, 2, 1, 0] } },
                        TE => { cost => { W => 2, C => 5 },
                                income => { P => [ 3, 2, 1, 0 ] } },
                        SH => { cost => { W => 4, C => 6 },
                                gain => { PW => 12 },
                                income => { C => [ 6, 0 ] } },
                        SA => { cost => { W => 4, C => 6 },
                                income => { P => [ 1, 0 ] } },
                    }},
    darklings => { 
        C => 15, W => 1, P => 1, P1 => 5, P2 => 7,
        WATER => 1, EARTH => 1,
        color => 'black',
        ship => { 
            level => 0,
            advance_cost => { C => 4, P => 1 },
            advance_gain => [ { VP => 2 },
                              { VP => 3 },
                              { VP => 4 } ]
        },
        dig => {
            level => 0,
            cost => [ { P => 1 } ],
            gain => [ { VP => 2 } ],
        },
        buildings => {
            D => { cost => { W => 1, C => 2 },
                   income => { W => [ 8, 8, 7, 6, 5, 4, 3, 2, 1 ] } },
            TP => { cost => { W => 2, C => 3 },
                    income => { C => [ 8, 6, 4, 2, 0 ],
                                PW => [ 6, 4, 2, 1, 0] } },
            TE => { cost => { W => 2, C => 5 },
                    income => { P => [ 3, 2, 1, 0 ] } },
            SH => { cost => { W => 4, C => 6 },
                    ## FIXME: one-time W -> P conversion ability
                    income => { PW => [ 2, 0 ] } },
            SA => { cost => { W => 4, C => 10 },
                    income => { P => [ 2, 0 ] } },
        }
    },
    auren => { C => 15, W => 3, P1 => 5, P2 => 7,
               WATER => 1, AIR => 1,
               color => 'green',
               ship => { 
                   level => 0,
                   advance_cost => { C => 4, P => 1 },
                   advance_gain => [ { VP => 2 },
                                     { VP => 3 },
                                     { VP => 4 } ]
               },
               dig => {
                   level => 0,
                   cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                   advance_cost => { W => 2, C => 5, P => 1 },
                   advance_gain => [ { VP => 6 },
                                     { VP => 6 } ]
               },
               buildings => {
                   D => { cost => { W => 1, C => 2 },
                          income => { W => [ 8, 8, 7, 6, 5, 4, 3, 2, 1 ] } },
                   TP => { cost => { W => 2, C => 3 },
                           income => { C => [ 8, 6, 4, 2, 0 ],
                                       PW => [ 6, 4, 2, 1, 0] } },
                   TE => { cost => { W => 2, C => 5 },
                           income => { P => [ 3, 2, 1, 0 ] } },
                   SH => { cost => { W => 4, C => 6 },
                           gain => { ACTA => 1, GAIN_FAVOR => 1 },
                           income => { PW => [ 2, 0 ] } },
                   SA => { cost => { W => 4, C => 8 },
                           income => { P => [ 1, 0 ] } },
               }},
    mermaids => { 
        C => 15, W => 3, P1 => 3, P2 => 9,
        WATER => 2,
        color => 'blue',
        ship => { 
            level => 1,
            advance_cost => { C => 4, P => 1 },
            advance_gain => [ { VP => 0 },
                              { VP => 2 },
                              { VP => 3 },
                              { VP => 4 },
                              { VP => 5 } ]
        },
        dig => {
            level => 0,
            cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
            advance_cost => { W => 2, C => 5, P => 1 },
            advance_gain => [ { VP => 6 },
                              { VP => 6 } ]
        },
        buildings => {
            D => { cost => { W => 1, C => 2 },
                   income => { W => [ 8, 8, 7, 6, 5, 4, 3, 2, 1 ] } },
            TP => { cost => { W => 2, C => 3 },
                    income => { C => [ 8, 6, 4, 2, 0 ],
                                PW => [ 6, 4, 2, 1, 0] } },
            TE => { cost => { W => 2, C => 5 },
                    income => { P => [ 3, 2, 1, 0 ] } },
            SH => { cost => { W => 4, C => 6 },
                    gain => { GAIN_SHIP => 1 },
                    income => { PW => [ 4, 0 ] } },
            SA => { cost => { W => 4, C => 8 },
                    income => { P => [ 1, 0 ] } },
        }
    },
    swarmlings => { C => 20, W => 8, P1 => 3, P2 => 9,
                    FIRE => 1, EARTH => 1,
                    WATER => 1, AIR => 1, color => 'blue',
                    ship => { 
                        level => 0,
                        advance_cost => { C => 4, P => 1 },
                        advance_gain => [ { VP => 2 },
                                          { VP => 3 },
                                          { VP => 4 } ]
                    },
                    dig => {
                        level => 0,
                        cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                        advance_cost => { W => 2, C => 5, P => 1 },
                        advance_gain => [ { VP => 6 },
                                          { VP => 6 } ]
                    },
                    special => {
                        map(("TW$_", { W => 3 }), 1..5)
                    },
                    buildings => {
                        D => { cost => { W => 2, C => 3 },
                               income => { W => [ 9, 9, 8, 7, 6, 5, 4, 3, 2 ] } },
                        TP => { cost => { W => 3, C => 4 },
                                income => { PW => [ 8, 6, 4, 2, 0],
                                            C => [ 9, 6, 4, 2, 0] } },
                        TE => { cost => { W => 3, C => 6 },
                                income => { P => [ 3, 2, 1, 0 ] } },
                        SH => { cost => { W => 5, C => 8 },
                                gain => { ACTS => 1 },
                                income => { PW => [ 4, 0 ] } },
                        SA => { cost => { W => 5, C => 8 },
                                income => { P => [ 2, 0 ] } },
                    }},
    nomads => { C => 15, W => 2, P1 => 5, P2 => 7,
                FIRE => 1, EARTH => 1, color => 'yellow',
                ship => { 
                    level => 0,
                    advance_cost => { C => 4, P => 1 },
                    advance_gain => [ { VP => 2 },
                                      { VP => 3 },
                                      { VP => 4 } ]
                },
                dig => {
                    level => 0,
                    cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                    advance_cost => { W => 2, C => 5, P => 1 },
                    advance_gain => [ { VP => 6 },
                                      { VP => 6 } ]
                },
                buildings => {
                    D => { cost => { W => 1, C => 2 },
                           income => { W => [ 8, 8, 7, 6, 5, 4, 3, 2, 1 ] } },
                    TP => { cost => { W => 2, C => 3 },
                            income => { C => [ 11, 7, 4, 2, 0 ],
                                        PW => [ 4, 3, 2, 1, 0] } },
                    TE => { cost => { W => 2, C => 5 },
                            income => { P => [ 3, 2, 1, 0 ] } },
                    SH => { cost => { W => 4, C => 8 },
                            gain => { ACTN => 1 },
                            income => { PW => [ 2, 0 ] } },
                    SA => { cost => { W => 4, C => 6 },
                            income => { P => [ 1, 0 ] } },
                }},
    engineers => { C => 10, W => 2, P1 => 3, P2 => 9, color => 'gray',
                   ship => { 
                       level => 0,
                       advance_cost => { C => 4, P => 1 },
                       advance_gain => [ { VP => 2 },
                                         { VP => 3 },
                                         { VP => 4 } ]
                   },
                   dig => {
                       level => 0,
                       cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                       advance_cost => { W => 2, C => 5, P => 1 },
                       advance_gain => [ { VP => 6 },
                                         { VP => 6 } ]
                   },
                   buildings => {
                    D => { cost => { W => 1, C => 1 },
                           income => { W => [ 6, 5, 4, 4, 3, 2, 2, 1, 0 ] } },
                    TP => { cost => { W => 1, C => 2 },
                            income => { C => [ 8, 6, 4, 2, 0 ],
                                        PW => [ 6, 4, 2, 1, 0] } },
                    TE => { cost => { W => 1, C => 4 },
                            income => { P => [ 2, 1, 1, 0 ],
                                        PW => [ 5, 5, 0, 0 ] } },
                    SH => { cost => { W => 3, C => 6 },
                            income => { PW => [2, 0 ] } },
                    SA => { cost => { W => 3, C => 6 },
                            income => { P => [ 1, 0 ] } },
               }},
    chaosmagicians => { 
        C => 15, W => 3, P1 => 5, P2 => 7,
        FIRE => 2,
        color => 'red',
        ship => { 
            level => 0,
            advance_cost => { C => 4, P => 1 },
            advance_gain => [ { VP => 2 },
                              { VP => 3 },
                              { VP => 4 } ]
        },
        dig => {
            level => 0,
            cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
            advance_cost => { W => 2, C => 5, P => 1 },
            advance_gain => [ { VP => 6 },
                              { VP => 6 } ]
        },
        buildings => {
            D => { cost => { W => 1, C => 2 },
                   income => { W => [ 8, 8, 7, 6, 5, 4, 3, 2, 1 ] } },
            TP => { cost => { W => 2, C => 3 },
                    income => { C => [ 8, 6, 4, 2, 0 ],
                                PW => [ 6, 4, 2, 1, 0] } },
            TE => { cost => { W => 2, C => 5 },
                    gain => { GAIN_FAVOR => 2 },
                    income => { P => [ 3, 2, 1, 0 ] } },
            SH => { cost => { W => 4, C => 4 },
                    gain => { ACTC => 1 },
                    income => { W => [ 2, 0 ] } },
            SA => { cost => { W => 4, C => 8 },
                    gain => { GAIN_FAVOR => 2 },
                    income => { P => [ 1, 0 ] } },
        }
    },
);

my %actions = (
    ACT1 => { cost => { PW => 3 }, gain => {}},
    ACT2 => { cost => { PW => 3 }, gain => { P => 1 } },
    ACT3 => { cost => { PW => 4 }, gain => { W => 2 } },
    ACT4 => { cost => { PW => 4 }, gain => { C => 7 } },
    ACT5 => { cost => { PW => 4 }, gain => { SHOVEL => 1 } },
    ACT6 => { cost => { PW => 6 }, gain => { SHOVEL => 2 } },
    ACTA => { cost => {}, gain => { CULT => 2} },
    ACTS => { cost => {}, gain => { FREE_TP => 1 } },
    ACTN => { cost => {}, gain => { FREE_TF => 1 } },
    BON1 => { cost => {}, gain => { SHOVEL => 1 } },
    BON2 => { cost => {}, gain => { CULT => 1 } },
    FAV6 => { cost => {}, gain => { CULT => 1 } },
);
        
my %tiles = (
    BON1 => { income => { C => 2 } },
    BON2 => { income => { C => 4 } },
    BON3 => { income => { C => 6 } },
    BON4 => { income => { PW => 3 }, special => { ship => 1 } },
    BON5 => { income => { PW => 3, W => 1 } },
    BON6 => { income => { W => 2 },
              pass_vp => { SA => [4, 0], SH => [4, 0] } },
    BON7 => { income => { W => 1 },
              pass_vp => { TP => [ reverse map { $_ * 2 } 0..4 ] } },
    BON8 => { income => { P => 1 } },
    BON9 => { income => { C => 2 },
              pass_vp => { D => [ reverse map { $_ } 0..8 ] } },

    FAV1 => { gain => { FIRE => 3 }, income => {} },
    FAV2 => { gain => { WATER => 3 }, income => {} },
    FAV3 => { gain => { EARTH => 3 }, income => {} },
    FAV4 => { gain => { AIR => 3 }, income => {} },

    FAV5 => { gain => { FIRE => 2 }, income => {} }, # Town
    FAV6 => { gain => { WATER => 2 }, income => {} },
    FAV7 => { gain => { EARTH => 2 }, income => { W => 1, PW => 1} },
    FAV8 => { gain => { AIR => 2 }, income => { PW => 4} },

    FAV9 => { gain => { FIRE => 1 }, income => { C => 3} },
    FAV10 => { gain => { WATER => 1 }, income => {}, vp => { TP => 3 } },
    FAV11 => { gain => { EARTH => 1 }, income => {}, vp => { D => 2 } },
    FAV12 => { gain => { AIR => 1 }, income => {},
               pass_vp => { TP => [4, 3, 3, 2, 0] } },

    SCORE1 => { vp => { SHOVEL => 2 },
                vp_display => 'SHOVEL >> 2',
                cult => 'EARTH',
                req => 1, 
                income => { C => 1 } },
    SCORE2 => { vp => { map(("TW$_", 5), 1..5) },
                vp_display => 'TOWN >> 5',
                cult => 'EARTH',
                req => 4, 
                income => { SHOVEL => 1 } },
    SCORE3 => { vp => { D => 2 },
                vp_display => 'D >> 2',
                cult => 'WATER',
                req => 4, 
                income => { P => 1 } },    
    SCORE4 => { vp => { SA => 5, SH => 5 },
                vp_display => 'SA/SH >> 5',
                cult => 'FIRE',
                req => 2,
                income => { W => 1 } },    
    SCORE5 => { vp => { D => 2 },
                vp_display => 'D >> 2',
                cult => 'FIRE',
                req => 4, 
                income => { PW => 4 } },    
    SCORE6 => { vp => { TP => 3 },
                vp_display => 'TP >> 3',
                cult => 'WATER',
                req => 4, 
                income => { SHOVEL => 1 } },    
    SCORE7 => { vp => { SA => 5, SH => 5 },
                vp_display => 'SA/SH >> 5',
                cult => 'AIR',
                req => 2,
                income => { W => 1 } },    
    SCORE8 => { vp => { TP => 3 },
                vp_display => 'TP >> 3',
                cult => 'AIR',
                req => 4, 
                income => { SHOVEL => 1 } },    

    TW1 => { gain => { VP => 5, C => 6 } },
    TW2 => { gain => { VP => 7, W => 2 } },
    TW3 => { gain => { VP => 9, P => 1 } },
    TW4 => { gain => { VP => 6, PW => 8 } },
    TW5 => { gain => { VP => 8, FIRE => 1, WATER => 1, EARTH => 1, AIR => 1 } }
);

for (keys %tiles) {
    if (/^SCORE/) {
        my $tile = $tiles{$_};
        my $currency = (keys %{$tile->{income}})[0];
        $tile->{income_display} =
            sprintf("%d %s -> %d %s", $tile->{req}, $tile->{cult},
                    $tile->{income}{$currency}, $currency);
    }
    if ($actions{$_}) {
        $tiles{$_}{action} = $actions{$_};
    }
}

my %pool = (
    # Resources
    C => 1000,
    W => 1000,
    P => 1000,
    VP => 1000,

    # Power
    P1 => 10000,
    P2 => 10000,
    P3 => 10000,

    # Cult tracks
    EARTH => 100,
    FIRE => 100,
    WATER => 100,
    AIR => 100,

    # Temporary pseudo-resources for tracking activation effects
    SHOVEL => 10000,
    FREE_TF => 10000,
    FREE_TP => 10000,
    CULT => 10000,
    GAIN_FAVOR => 10000,
    GAIN_SHIP => 10000,
);

$pool{"ACT$_"}++ for 1..6;
$pool{"BON$_"}++ for 1..9;
$map{"BON$_"}{C} = 0 for 1..9;
$pool{"FAV$_"}++ for 1..4;
$pool{"FAV$_"} += 3 for 5..12;
$pool{"TW$_"} += 2 for 1..5;

for my $cult (@cults) {
    $map{"${cult}1"} = { gain => { $cult => 3 } };
    $map{"${cult}$_"} = { gain => { $cult => 2 } } for 2..4;
}

my @map = qw(brown gray green blue yellow red brown black red green blue red black E
             yellow x x brown black x x yellow black x x yellow E
             x x black x gray x green x green x gray x x E
             green blue yellow x x red blue x red x red brown E
             black brown red blue black brown gray yellow x x green black blue E
             gray green x x yellow green x x x brown gray brown E
             x x x gray x red x green x yellow black blue yellow E
             yellow blue brown x x x blue black x gray brown gray E
             red black gray blue red green yellow brown gray x blue green red E); 
my @bridges = ();

{
    my $ri = 0;
    for my $row ('A'..'I') {
        my $col = 1;
        for my $ci (0..13) {
            my $color = shift @map;
            last if $color eq 'E';
            if ($color ne 'x') {
                $map{"$row$col"}{color} = $color;
                $map{"$row$col"}{row} = $ri;
                $map{"$row$col"}{col} = $ci;
                $col++;
            }
        }
        $ri++;
    }
}

## 

sub command;

sub setup {
    my $faction_name = lc shift;

    die "Unknown faction: $faction_name\n" if !$setups{$faction_name};

    my $faction = $factions{$faction_name} = $setups{$faction_name};    

    $faction->{P} ||= 0;
    $faction->{P1} ||= 0;
    $faction->{P2} ||= 0;
    $faction->{P3} ||= 0;

    for (@cults) {
        $faction->{$_} ||= 0;
    }

    $faction->{D} = 8;
    $faction->{TP} = 4;
    $faction->{SH} = 1;
    $faction->{TE} = 3;
    $faction->{SA} = 1;
    $faction->{VP} = 20;

    $faction->{buildings}{TE}{gain}{GAIN_FAVOR} ||= 1;
    $faction->{buildings}{SA}{gain}{GAIN_FAVOR} ||= 1;

    $faction->{SHOVEL} = 0;

    push @factions, $faction_name;
}

sub current_score_tile {
    if ($round > 0) {
        return $tiles{$score_tiles[$round - 1]};
    }
}

sub pay {
    my ($faction_name, $cost) = @_;

    for my $currency (keys %{$cost}) {
        my $amount = $cost->{$currency};
        command $faction_name, "-${amount}$currency";            
    }
}

sub gain {
    my ($faction_name, $cost) = @_;

    for my $currency (keys %{$cost}) {
        my $amount = $cost->{$currency};
        command $faction_name, "+${amount}$currency";            
    }
}

sub maybe_score_current_score_tile {
    my ($faction_name, $type) = @_;

    my $scoring = current_score_tile;
    if ($scoring) {
        my $gain = $scoring->{vp}{$type};
        if ($gain) {
            command $faction_name, "+${gain}vp"
        }
    }
}

sub maybe_score_favor_tile {
    my ($faction_name, $type) = @_;

    for my $tile (keys %{$factions{$faction_name}}) {
        if ($tile =~ /^FAV/) {
            my $scoring = $tiles{$tile}{vp};
            if ($scoring) {
                my $gain = $scoring->{$type};
                if ($gain) {
                    command $faction_name, "+${gain}vp"
                }
            }
        }
    }
}

sub maybe_gain_faction_special {
    my ($faction_name, $type) = @_;
    my $faction = $factions{$faction_name};

    my $enable_if = $faction->{special}{enable_if};
    if ($enable_if) {
        for my $currency (keys %{$enable_if}) {
            return if $faction->{$currency} != $enable_if->{$currency};
        }
    }

    gain $faction_name, $faction->{special}{$type};
}

sub faction_income {
    my $faction_name = shift;
    my $faction = $factions{$faction_name};

    my %total_income = map { $_, 0 } qw(C W P PW);

    my %buildings = %{$faction->{buildings}};
    for my $building (keys %buildings) {
        if (exists $buildings{$building}{income}) {
            my %building_income = %{$buildings{$building}{income}};
            for my $type (keys %building_income) {
                my $delta = $building_income{$type}[$faction->{$building}];
                if ($delta) {
                    $total_income{$type} += $delta;
                }
            }
        }
    }

    for my $tile (keys %{$faction}) {
        if (!$faction->{$tile}) {
            next;
        }

        if ($tile =~ /^BON|FAV/) {
            my $tile_income = $tiles{$tile}{income};
            for my $type (keys %{$tile_income}) {
                $total_income{$type} += $tile_income->{$type};
            }
        }
    }

    my $scoring = current_score_tile;
    if ($scoring) {
        my %scoring_income = %{$scoring->{income}};

        my $mul = int($faction->{$scoring->{cult}} / $scoring->{req});
        for my $type (keys %scoring_income) {
            $total_income{$type} += $scoring_income{$type} * $mul;
        }        
    }

    return %total_income;
}

sub maybe_gain_power_from_cult {
    my ($faction_name, $old_value, $new_value) = @_;
    my $faction = $factions{$faction_name};

    if ($old_value <= 2 && $new_value > 2) {
        command $faction_name, "+1pw";
    }
    if ($old_value <= 4 && $new_value > 4) {
        command $faction_name, "+2pw";
    }
    if ($old_value <= 6 && $new_value > 6) {
        command $faction_name, "+2pw";
    }
    if ($old_value <= 9 && $new_value > 9) {
        command $faction_name, "+3pw";
    }
}

my @colors = qw(yellow brown black blue green gray red);
my %colors = ();
$colors{$colors[$_]} = $_ for 0..$#colors;

sub color_difference {
    my ($a, $b) = @_;
    my $diff = abs $colors{$a} - $colors{$b};

    if ($diff > 3) {
        $diff = 7 - $diff;
    }

    return $diff;
}

sub gain_power {
    my ($faction_name, $count) = @_;
    my $faction = $factions{$faction_name};

    for (1..$count) {
        if ($faction->{P1}) {
            $faction->{P1}--;
            $faction->{P2}++;
        } elsif ($faction->{P2}) {
            $faction->{P2}--;
            $faction->{P3}++;
        } else {
            return $_ - 1;
        }
    }

    return $count;
}

sub command {
    my ($faction_name, $command) = @_;
    my $type;
    my $faction = $faction_name ? $factions{$faction_name} : undef;

    if ($command =~ /^([+-])(\d*)(\w+)$/) {
        die "Need faction for command $command\n" if !$faction_name;
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));
        my $delta = $sign * $count;
        $type = uc $3;

        if ($type eq 'GAIN_SHIP') {
            for (1..$delta) {
                my $track = $faction->{ship};
                my $gain = $track->{advance_gain}[$track->{level}];
                gain $faction_name, $gain;
                $track->{level}++
            }
            $type = '';
        } elsif ($type eq 'PW') {
            if ($sign > 0) {
                gain_power $faction_name, $count;
                $type = '';
            } else {
                $faction->{P1} += $count;
                $faction->{P3} -= $count;
                $type = 'P3';
            }
        } else {
            my $orig_value = $faction->{$type};

            # Pseudo-resources not in the pool, but revealed by removing
            # buildings.
            if ($type !~ /^ACT.$/) {
                $pool{$type} -= $delta;
            }
            $faction->{$type} += $delta;

            if (exists $pool{$type} and $pool{$type} < 0) {
                die "Not enough '$type' in pool after command '$command'\n";
            }

            if ($type =~ /^FAV/) {
                if (!$faction->{GAIN_FAVOR}) {
                    die "Taking favor tile not allowed\n";
                } else {
                    $faction->{GAIN_FAVOR}--;
                }

                gain $faction_name, $tiles{$type}{gain};
            }

            if ($type =~ /^TW/) {
                gain $faction_name, $tiles{$type}{gain};
            }

            if (grep { $_ eq $type } @cults) {
                if ($faction->{CULT}) {
                    $faction->{CULT} -= $delta;
                }

                my $new_value = $faction->{$type};
                maybe_gain_power_from_cult $faction_name, $orig_value, $new_value;
            }

            if ($sign > 0) {
                for (1..$count) {
                    maybe_score_current_score_tile $faction_name, $type;
                    maybe_gain_faction_special $faction_name, $type;
                }
            }
        }

        if ($type =~ /^BON/) {
            $faction->{C} += $map{$type}{C};
            $map{$type}{C} = 0;
        }
    }  elsif ($command =~ /^build (\w+)$/) {
        die "Need faction for command $command\n" if !$faction_name;

        my $free = ($round == 0);
        my $where = uc $1;
        my $type = 'D';
        die "Unknown location '$where'" if !$map{$where};

        die "'$where' already contains a $map{$where}{building}"
            if $map{$where}{building};

        if ($faction->{FREE_D}) {
            $free = 1;
            $faction->{FREE_D}--;
        }

        if (!$free) {
            pay $faction_name, $faction->{buildings}{$type}{cost};
        }

        maybe_score_favor_tile $faction_name, $type;
        maybe_score_current_score_tile $faction_name, $type;

        $map{$where}{building} = $type;
        my $color = $faction->{color};

        command $faction_name, "$where:$color";

        $faction->{$type}--;
    } elsif ($command =~ /^upgrade (\w+) to (\w+)$/) {
        die "Need faction for command $command\n" if !$faction_name;

        my $free = 0;
        $type = uc $2;
        my $where = uc $1;
        die "Unknown location '$where'" if !$map{$where};

        my $color = $faction->{color};
        die "$where has wrong color ($color vs $map{$where}{color})\n" if
            $map{$where}{color} ne $color;

        my %wanted_oldtype = (TP => 'D', TE => 'TP', SH => 'TP', SA => 'TE');
        my $oldtype = $map{$where}{building};

        if ($oldtype ne $wanted_oldtype{$type}) {
            die "$where contains ə $oldtype, wanted $wanted_oldtype{$type}"
        }

        $faction->{$oldtype}++;

        gain $faction_name, $faction->{buildings}{$type}{gain};

        if ($type eq 'TP' and $faction->{FREE_TP}) {
            $free = 1;
            $faction->{FREE_TP}--;
        }

        if (!$free) {
            pay $faction_name, $faction->{buildings}{$type}{cost};
        }

        maybe_score_favor_tile $faction_name, $type;
        maybe_score_current_score_tile $faction_name, $type;

        $map{$where}{building} = $type;

        $faction->{$type}--;
    } elsif ($command =~ /^(p)->(\w+)$/) {
        die "Need faction for command $command\n" if !$faction_name;

        $type = uc $1;
        my $free = 0;
        my $where = uc $2;
        die "Unknown location '$where'" if !$map{$where};

        my $oldtype = $map{$where}{building};
        die "$where already contains a priest" if $oldtype;

        if (exists $map{$where}{gain}) {
            gain $faction_name, $map{$where}{gain};
            delete $map{$where}{gain};
        }

        $map{$where}{building} = $type;
        $map{$where}{color} = $faction->{color};

        $faction->{$type}--;
    } elsif ($command =~ /^burn (\d+)$/) {
        die "Need faction for command $command\n" if !$faction_name;
        $faction->{P2} -= 2*$1;
        $faction->{P3} += $1;
        $type = 'P2';
    } elsif ($command =~ /^leech (\d+)$/) {
        die "Need faction for command $command\n" if !$faction_name;
        my $pw = $1;
        my $actual_pw = gain_power $faction_name, $pw;
        my $vp = $actual_pw - 1;

        if ($actual_pw > 0) {
            command $faction_name, "-${vp}VP";
        }
    } elsif ($command =~ /^(\w+):(\w+)$/) {
        my $where = uc $1;
        my $color = lc $2;
        if ($faction->{FREE_TF}) {
            command $faction_name, "-FREE_TF";            
        } else {
            my $color_difference = color_difference $map{$where}{color}, $color;

            if ($faction_name eq 'Giants' and $color_difference != 0) {
                $color_difference = 2;
            }

            command $faction_name, "-${color_difference}SHOVEL";
        } 

        $map{$where}{color} = $color;
    } elsif ($command =~ /^dig (\d+)/) {
        my $cost = $faction->{dig}{cost}[$faction->{dig}{level}];
        my $gain = $faction->{dig}{gain}[$faction->{dig}{level}];

        command $faction_name, "+${1}SHOVEL";
        pay $faction_name, $cost for 1..$1;
        gain $faction_name, $gain for 1..$1;
    } elsif ($command =~ /^bridge (\w+):(\w+)$/) {
        die "Need faction for command $command\n" if !$faction_name;

        my $from = uc $1;
        my $to = uc $2;
        push @bridges, {from => $from, to => $to, color => $faction->{color}};
    } elsif ($command =~ /^pass (\w+)$/) {
        die "Need faction for command $command\n" if !$faction_name;
        my $bon = $1;

        $faction->{passed} = 1;
        for (keys %{$faction}) {
            next if !$faction->{$_};

            my $pass_vp;
            if (/^BON/) {
                command $faction_name, "-$_";
                
                $pass_vp = $tiles{$_}{pass_vp};
            } elsif (/FAV/) {
                $pass_vp = $tiles{$_}{pass_vp};
            }

            if ($pass_vp) {
                for my $type (keys %{$pass_vp}) {
                    my $x = $pass_vp->{$type}[$faction->{$type}];
                    command $faction_name, "+${x}vp";
                }
            }                
        }
        command $faction_name, "+$bon"
    } elsif ($command =~ /^action (\w+)$/) {
        my $where = uc $1;
        my $name = $where;
        if ($where !~ /^ACT/) {
            $where .= "/$faction_name";
        }

        if ($actions{$name}) {
            pay $faction_name, $actions{$name}{cost};
            gain $faction_name, $actions{$name}{gain};
        } else {
            die "Unknown action $name";
        }

        if ($map{$where}{blocked}) {
            die "Action space $where is blocked"
        }
        $map{$where}{blocked} = 1;
    } elsif ($command =~ /^start$/) {
        $round++;

        for my $faction_name (@factions) {
            my $faction = $factions{$faction_name};
            die "Round $round income not taken for $faction_name\n" if
                !$faction->{income_taken};
            $faction->{income_taken} = 0;
            $faction->{passed} = 0 for keys %factions;
        }

        $map{$_}{blocked} = 0 for keys %map;
        for (1..9) {
            if ($pool{"BON$_"}) {
                $map{"BON$_"}{C}++;
            }
        }
    } elsif ($command =~ /^setup (\w+)$/) {
        setup $1;
    } elsif ($command =~ /delete (\w+)$/) {
        delete $pool{uc $1};
    } elsif ($command =~ /^income$/) {
        die "Need faction for command $command\n" if !$faction_name;

        die "Taking income twice for $faction_name" if
            $faction->{income_taken};

        my %income = faction_income $faction_name;
        gain $faction_name, \%income;
        
        $faction->{income_taken} = 1
    } elsif ($command =~ /^advance (ship|dig)/) {
        die "Need faction for command $command\n" if !$faction_name;

        my $type = lc $1;
        my $track = $faction->{$type};

        pay $faction_name, $track->{advance_cost};

        my $gain = $track->{advance_gain}[$track->{level}];

        if (!$gain) {
            die "Can't advance $type from level $track->{level}\n"; 
        }
        
        gain $faction_name, $gain;

        $track->{level}++;
    } elsif ($command =~ /^score (.*)/) {
        my $setup = uc $1;
        @score_tiles = split /,/, $setup;
        die "Invalid scoring tile setup: $setup\n" if @score_tiles != 6;
    } else {
        die "Could not parse command '$command'.\n";
    }

    if ($type and $faction_name) {
        if ($faction->{$type} < 0) {
            die "Not enough '$type' in $faction_name after command '$command'\n";
        }
    }
}

sub handle_row {
    local $_ = shift;

    # Comment
    if (s/#(.*)//) {
        push @ledger, { comment => $1 };
    }

    s/\s+/ /g;

    my $prefix = '';

    if (s/^(.*?)://) {
        $prefix = lc $1;
    }

    my @commands = split /[.]/, $_;

    for (@commands) {
        s/^\s+//;
        s/\s+$//;
        s/(\W)\s(\w)/$1$2/g;
        s/(\w)\s(\W)/$1$2/g;
    }

    @commands = grep { /\S/ } @commands;

    return if !@commands;

    if ($factions{$prefix} or $prefix eq '') {
        my @fields = qw(VP C W P P1 P2 P3 PW D TP TE SH SA
                        FIRE WATER EARTH AIR CULT);
        my %old_data = map { $_, $factions{$prefix}{$_} } @fields; 

        for my $command (@commands) {
            command $prefix, lc $command;
        }

        my %new_data = map { $_, $factions{$prefix}{$_} } @fields;

        if ($prefix) {
            $old_data{PW} = $old_data{P2} + 2 * $old_data{P3};
            $new_data{PW} = $new_data{P2} + 2 * $new_data{P3};

            $old_data{CULT} = sum @old_data{@cults};
            $new_data{CULT} = sum @new_data{@cults};

            my %delta = map { $_, $new_data{$_} - $old_data{$_} } @fields;
            my %pretty_delta = map { $_, ($delta{$_} ?
                                          sprintf "%+d [%d]", $delta{$_}, $new_data{$_} :
                                          '')} @fields;
            if ($delta{PW}) {
                $pretty_delta{PW} = sprintf "%+d [%d/%d/%d]", $delta{PW}, $new_data{P1}, $new_data{P2}, $new_data{P3};
            }

            if ($delta{CULT}) {
                $pretty_delta{CULT} = sprintf "%+d [%d/%d/%d/%d]", $delta{CULT}, $new_data{FIRE}, $new_data{WATER}, $new_data{EARTH}, $new_data{AIR};
            }

            my $warn = '';
            if ($factions{$prefix}{SHOVEL}) {
                 $warn = "Unused shovels for $prefix\n";
            }

            if ($factions{$prefix}{FREE_TF}) {
                $warn = "Unused free terraform for $prefix\n";
            }

            if ($factions{$prefix}{FREE_TP}) {
                $warn = "Unused free trading post for $prefix\n";
            }

            if ($factions{$prefix}{CULT}) {
                $warn = "Unused cult advance for $prefix\n";
            }

            if ($factions{$prefix}{GAIN_FAVOR}) {
                $warn = "favor not taken by $prefix\n";
            }

            push @ledger, { faction => $prefix,
                            warning => $warn,
                            commands => (join ". ", @commands),
                            map { $_, $pretty_delta{$_} } @fields};

        }
    } else {
        die "Unknown prefix: '$prefix' (expected one of ".
            (join ", ", keys %factions).
            ")\n";
    }
}

sub print_json {
    my $out = encode_json {
        order => \@factions,
        map => \%map,
        factions => \%factions,
        pool => \%pool,
        bridges => \@bridges,
        ledger => \@ledger,
        error => \@error,
        # tiles => \%tiles,
        towns => { map({$_, $tiles{$_}} grep { /^TW/ } keys %tiles ) },
        score_tiles => [ map({$tiles{$_}} @score_tiles ) ],
        bonus_tiles => { map({$_, $tiles{$_}} grep { /^BON/ } keys %tiles ) },
        favors => { map({$_, $tiles{$_}} grep { /^FAV/ } keys %tiles ) },
    };

    print $out;
}

while (<>) {
    eval { handle_row $_ };
    if ($@) {
        chomp;
        push @error, "Error on line $. [$_]:";
        push @error, "$@\n";
        last;
    }
}

if ($round > 0) {
    for my $faction (@factions) {
        $factions{$faction}{income} = { faction_income $faction };
    }

    for (0..($round-2)) {
        $tiles{$score_tiles[$_]}->{old} = 1;
    }

    current_score_tile->{active} = 1;
    $tiles{$score_tiles[-1]}->{income_display} = '';
}

for my $faction (@factions) {
    delete $factions{$faction}{buildings};
}

print_json;

if (@error) {
    print STDERR $_ for @error;
    exit 1;
}
