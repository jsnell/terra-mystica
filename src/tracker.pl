#!/usr/bin/perl -wl

use strict;
use JSON;

my @factions;
my %factions;
my @cults = qw(EARTH FIRE WATER AIR);
my @ledger = ();
my %map = ();
my @error = ();
my @score_tiles = ();
my $turn = 0;

my %setups = (
    Alchemists => { C => 15, W => 3, P1 => 5, P2 => 7,
                    WATER => 1, FIRE => 1, color => 'black',
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
    Auren => { C => 15, W => 3, P1 => 5, P2 => 7,
               WATER => 1, AIR => 1,
               color => 'green',
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
    Swarmlings => { C => 20, W => 8, P1 => 3, P2 => 9,
                    FIRE => 1, EARTH => 1,
                    WATER => 1, AIR => 1, color => 'blue',
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
    Nomads => { C => 15, W => 2, P1 => 5, P2 => 7,
                FIRE => 1, EARTH => 1, color => 'yellow',
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
    Engineers => { C => 10, W => 2, P1 => 3, P2 => 9, color => 'gray',
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
        
my %bonus_tiles = (
    BON1 => { income => { C => 2 } },
    BON2 => { income => { C => 4 } },
    BON3 => { income => { C => 6 } },
    BON4 => { income => { PW => 3 } },
    BON5 => { income => { PW => 3, W => 1 } },
    BON6 => { income => { W => 2 },
              pass_vp => { SA => [4, 0], SH => [4, 0] } },
    BON7 => { income => { W => 1 },
              pass_vp => { TP => [ reverse map { $_ * 2 } 0..4 ] } },
    BON8 => { income => { P => 1 } },
    BON9 => { income => { C => 2 },
              pass_vp => { D => [ reverse map { $_ } 0..8 ] } },
);

my %favors = (
    FAV1 => { gain => { FIRE => 3 }, income => {} },
    FAV2 => { gain => { WATER => 3 }, income => {} },
    FAV3 => { gain => { EARTH => 3 }, income => {} },
    FAV4 => { gain => { AIR => 3 }, income => {} },

    FAV5 => { gain => { FIRE => 2 }, income => {} }, # Town
    FAV6 => { gain => { WATER => 2 }, income => {} }, # +1 cult
    FAV7 => { gain => { EARTH => 2 }, income => { W => 1, PW => 1} },
    FAV8 => { gain => { AIR => 2 }, income => { PW => 4} },

    FAV9 => { gain => { FIRE => 1 }, income => { C => 3} },
    FAV10 => { gain => { WATER => 1 }, income => {}, vp => { TP => 3 } },
    FAV11 => { gain => { EARTH => 1 }, income => {}, vp => { D => 2 } },
    FAV12 => { gain => { AIR => 1 }, income => {},
               pass_vp => { TP => [4, 3, 3, 2, 0] } },
);

my %score_tiles = (
    SCORE1 => { vp => { SHOVEL => 2 },
                vp_display => '2 / sh',
                cult => 'EARTH',
                req => 1, 
                income => { C => 1 } },
    SCORE2 => { vp => { }, # vps filled in later
                vp_display => '5 / town',
                cult => 'EARTH',
                req => 4, 
                income => { SHOVEL => 1 } },
    SCORE3 => { vp => { D => 2 },
                vp_display => '2 / D',
                cult => 'WATER',
                req => 4, 
                income => { P => 1 } },    
    SCORE4 => { vp => { SA => 5, SH => 5 },
                vp_display => '5 / SA or SH',
                cult => 'FIRE',
                req => 2,
                income => { W => 1 } },    
    SCORE5 => { vp => { D => 2 },
                vp_display => '2 / D',
                cult => 'FIRE',
                req => 4, 
                income => { PW => 4 } },    
    SCORE6 => { vp => { TP => 3 },
                vp_display => '3 / TP',
                cult => 'WATER',
                req => 4, 
                income => { SHOVEL => 1 } },    
    SCORE7 => { vp => { SA => 5, SH => 5 },
                vp_display => '5 / SA or SH',
                cult => 'AIR',
                req => 2,
                income => { W => 1 } },    
    SCORE8 => { vp => { TP => 3 },
                vp_display => '3 / TP',
                cult => 'AIR',
                req => 4, 
                income => { SHOVEL => 1 } },    
);

my %towns = (
    TW1 => { gain => { VP => 5, C => 6 } },
    TW2 => { gain => { VP => 7, W => 2 } },
    TW3 => { gain => { VP => 9, P => 1 } },
    TW4 => { gain => { VP => 6, PW => 8 } },
    TW5 => { gain => { VP => 8, FIRE => 1, WATER => 1, EARTH => 1, AIR => 1 } }
);

for (keys %score_tiles) {
    my $tile = $score_tiles{$_};
    my $currency = (keys %{$tile->{income}})[0];
    $tile->{income_display} =
        sprintf("%d %s -> %d %s", $tile->{req}, $tile->{cult},
                $tile->{income}{$currency}, $currency);
}

$score_tiles{SCORE2}{vp}{"TW$_"} = 5 for 1..5;

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
    my $faction = ucfirst shift;

    die "Unknown faction: $faction\n" if !$setups{$faction};

    $factions{$faction} = $setups{$faction};    
    $factions{$faction}{P} ||= 0;
    $factions{$faction}{P1} ||= 0;
    $factions{$faction}{P2} ||= 0;
    $factions{$faction}{P3} ||= 0;

    for (@cults) {
        $factions{$faction}{$_} ||= 0;
    }

    $factions{$faction}{D} = 8;
    $factions{$faction}{TP} = 4;
    $factions{$faction}{SH} = 1;
    $factions{$faction}{TE} = 3;
    $factions{$faction}{SA} = 1;
    $factions{$faction}{VP} = 20;

    $factions{$faction}{buildings}{TE}{gain}{GAIN_FAVOR} ||= 1;
    $factions{$faction}{buildings}{SA}{gain}{GAIN_FAVOR} ||= 1;

    $factions{$faction}{SHOVEL} = 0;

    push @factions, $faction;
}

sub current_score_tile {
    if ($turn > 0) {
        return $score_tiles{$score_tiles[$turn - 1]};
    }
}

sub maybe_score_current_score_tile {
    my ($faction, $type) = @_;

    my $scoring = current_score_tile;
    if ($scoring) {
        my $gain = $scoring->{vp}{$type};
        if ($gain) {
            command $faction, "+${gain}vp"
        }
    }
}

sub maybe_score_favor_tile {
    my ($faction, $type) = @_;

    for my $tile (keys %{$factions{$faction}}) {
        if ($tile =~ /^FAV/) {
            my $scoring = $favors{$tile}{vp};
            if ($scoring) {
                my $gain = $scoring->{$type};
                if ($gain) {
                    command $faction, "+${gain}vp"
                }
            }
        }
    }
}

sub faction_income {
    my $faction = shift;
    my %total_income = map { $_, 0 } qw(C W P PW);

    my %buildings = %{$factions{$faction}{buildings}};
    for my $building (keys %buildings) {
        if (exists $buildings{$building}{income}) {
            my %building_income = %{$buildings{$building}{income}};
            for my $type (keys %building_income) {
                my $delta = $building_income{$type}[$factions{$faction}{$building}];
                if ($delta) {
                    $total_income{$type} += $delta;
                }
            }
        }
    }

    for my $tile (keys %{$factions{$faction}}) {
        if (!$factions{$faction}{$tile}) {
            next;
        }

        my %tile_income = ();

        if ($tile =~ /^BON/) {
            %tile_income = %{$bonus_tiles{$tile}{income}};
        } elsif ($tile =~ /^FAV/) {
            %tile_income = %{$favors{$tile}{income}};
        }

        for my $type (keys %tile_income) {
            $total_income{$type} += $tile_income{$type};
        }
    }

    my $scoring = current_score_tile;
    if ($scoring) {
        my %scoring_income = %{$scoring->{income}};

        my $mul = int($factions{$faction}{$scoring->{cult}} / $scoring->{req});
        for my $type (keys %scoring_income) {
            $total_income{$type} += $scoring_income{$type} * $mul;
        }        
    }

    return %total_income;
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

sub command {
    my ($faction, $command) = @_;
    my $type;

    if ($command =~ /^([+-])(\d*)(\w+)$/) {
        die "Need faction for command $command\n" if !$faction;
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));
        $type = uc $3;

        if ($type eq 'PW') {
            for (1..$count) {
                if ($sign > 0) {
                    if ($factions{$faction}{P1}) {
                        $factions{$faction}{P1}--;
                        $factions{$faction}{P2}++;
                        $type = 'P1';
                    } elsif ($factions{$faction}{P2}) {
                        $factions{$faction}{P2}--;
                        $factions{$faction}{P3}++;
                        $type = 'P2';
                    } else {
                        return $count - 1;
                    }
                } else {
                    $factions{$faction}{P1}++;
                    $factions{$faction}{P3}--;
                    $type = 'P3';
                }
            }

            return $count;
        } else {
            my $orig_value = $factions{$faction}{$type};

            # Pseudo-resources not in the pool, but revealed by removing
            # buildings.
            if ($type !~ /^ACT.$/) {
                $pool{$type} -= $sign * $count;
            }
            $factions{$faction}{$type} += $sign * $count;

            if (exists $pool{$type} and $pool{$type} < 0) {
                die "Not enough '$type' in pool after command '$command'\n";
            }

            if ($type =~ /^FAV/) {
                if (!$factions{$faction}{GAIN_FAVOR}) {
                    die "Taking favor tile not allowed\n";
                } else {
                    $factions{$faction}{GAIN_FAVOR}--;
                }

                my %gain = %{$favors{$type}{gain}};

                for (keys %gain) {
                    command $faction, "+$gain{$_}$_";
                }
            }

            if ($type =~ /^TW/) {
                my %gain = %{$towns{$type}{gain}};

                for (keys %gain) {
                    command $faction, "+$gain{$_}$_";
                }
            }

            if ($type =~ /FIRE|WATER|EARTH|AIR/) {
                my $new_value = $factions{$faction}{$type};
                if ($factions{$faction}{CULT}) {
                    $factions{$faction}{CULT} -= ($sign * $count);
                }

                if ($orig_value <= 2 && $new_value > 2) {
                    command $faction, "+1pw";
                }
                if ($orig_value <= 4 && $new_value > 4) {
                    command $faction, "+2pw";
                }
                if ($orig_value <= 6 && $new_value > 6) {
                    command $faction, "+2pw";
                }
                if ($orig_value <= 9 && $new_value > 9) {
                    command $faction, "+3pw";
                }
            }

            if ($sign > 0) {
                for (1..$count) {
                    maybe_score_current_score_tile $faction, $type;
                }
            }
        }

        if ($type =~ /^BON/) {
            $factions{$faction}{C} += $map{$type}{C};
            $map{$type}{C} = 0;
        }
    } elsif ($command =~ /^(free\s+)?(\w+)->(\w+)$/) {
        die "Need faction for command $command\n" if !$faction;

        my $free = $1;
        $type = uc $2;
        my $where = uc $3;
        die "Unknown location '$where'" if !$map{$where};

        my $oldtype = $map{$where}{building};
        if ($oldtype) {
            $factions{$faction}{$oldtype}++;
        }

        if (exists $map{$where}{gain}) {
            my %gain = %{$map{$where}{gain}};
            for my $type (keys %gain) {
                command $faction, "+$gain{$type}$type";
                delete $gain{$type};
            }
        }

        if (exists $factions{$faction}{buildings}{$type}{gain}) {
            my %gain = %{$factions{$faction}{buildings}{$type}{gain}};
            for my $type (keys %gain) {
                command $faction, "+$gain{$type}$type";
            }
        }

        if ($type eq 'TP' and $factions{$faction}{FREE_TP}) {
            $free = 1;
            $factions{$faction}{FREE_TP}--;
        }

        if (!$free and
            exists $factions{$faction}{buildings}{$type}{cost}) {
            my %cost = %{$factions{$faction}{buildings}{$type}{cost}};

            for my $type (keys %cost) {
                command $faction, "-$cost{$type}$type";
            }
        }

        maybe_score_favor_tile $faction, $type;
        maybe_score_current_score_tile $faction, $type;

        $map{$where}{building} = $type;
        my $color = $factions{$faction}{color};

        if (exists $map{$where}{color}) {
            command $faction, "$where:$color";
        } else {
            $map{$where}{color} = $color;
        }

        $factions{$faction}{$type}--;
    } elsif ($command =~ /^burn (\d+)$/) {
        die "Need faction for command $command\n" if !$faction;
        $factions{$faction}{P2} -= 2*$1;
        $factions{$faction}{P3} += $1;
        $type = 'P2';
    } elsif ($command =~ /^leech (\d+)$/) {
        die "Need faction for command $command\n" if !$faction;
        my $pw = $1;
        my $actual_pw = command $faction, "+${pw}PW";
        my $vp = $actual_pw - 1;

        if ($actual_pw > 0) {
            command $faction, "-${vp}VP";
        }
    } elsif ($command =~ /^(\w+):(\w+)$/) {
        my $where = uc $1;
        my $color = lc $2;
        if ($factions{$faction}{FREE_TF}) {
            command $faction, "-FREE_TF";            
        } else {
            my $color_difference = color_difference $map{$where}{color}, $color;

            if ($faction eq 'Giants' and $color_difference != 0) {
                $color_difference = 2;
            }

            command $faction, "-${color_difference}SHOVEL";
        } 

        $map{$where}{color} = $color;
    } elsif ($command =~ /^dig (\d+)/) {
        # XXX: Variable costs (shovel upgrades, swarmlings)
        my $cost = 3 * $1;

        command $faction, "+${1}SHOVEL";
        command $faction, "-${cost}W";
    } elsif ($command =~ /^bridge (\w+):(\w+)$/) {
        die "Need faction for command $command\n" if !$faction;

        my $from = uc $1;
        my $to = uc $2;
        push @bridges, {from => $from, to => $to, color => $factions{$faction}{color}};
    } elsif ($command =~ /^pass (\w+)$/) {
        die "Need faction for command $command\n" if !$faction;
        my $bon = $1;

        $factions{$faction}{passed} = 1;
        for (keys %{$factions{$faction}}) {
            next if !$factions{$faction}{$_};

            my $pass_vp;
            if (/^BON/) {
                command $faction, "-$_";
                
                $pass_vp = $bonus_tiles{$_}{pass_vp};
            } elsif (/FAV/) {
                $pass_vp = $favors{$_}{pass_vp};
            }

            if ($pass_vp) {
                for my $type (keys %{$pass_vp}) {
                    my $x = $pass_vp->{$type}[$factions{$faction}{$type}];
                    command $faction, "+${x}vp";
                }
            }                
        }
        command $faction, "+$bon"
    } elsif ($command =~ /^block (\w+)$/) {
        my $where = uc $1;
        if ($where !~ /^ACT/) {
            $where .= "/$faction";
        }
        if ($map{$where}{blocked}) {
            die "Action space $where is blocked"
        }
        $map{$where}{blocked} = 1;
    } elsif ($command =~ /^action (\w+)$/) {
        my $where = uc $1;
        my $name = $where;
        if ($where !~ /^ACT/) {
            $where .= "/$faction";
        }

        if ($actions{$name}) {
            my %cost = %{$actions{$name}{cost}};
            for my $currency (keys %cost) {
                command $faction, "-$cost{$currency}$currency";
            }
            my %gain = %{$actions{$name}{gain}};
            for my $currency (keys %gain) {
                command $faction, "+$gain{$currency}$currency";
            }
        } else {
            die "Unknown action $name";
        }

        if ($map{$where}{blocked}) {
            die "Action space $where is blocked"
        }
        $map{$where}{blocked} = 1;
    } elsif ($command =~ /^clear$/) {
        $map{$_}{blocked} = 0 for keys %map;
        $factions{$_}{passed} = 0 for keys %factions;
        for (1..9) {
            if ($pool{"BON$_"}) {
                $map{"BON$_"}{C}++;
            }
        }
        $turn++;
    } elsif ($command =~ /^setup (\w+)$/) {
        setup $1;
    } elsif ($command =~ /delete (\w+)$/) {
        delete $pool{uc $1};
    } elsif ($command =~ /^income$/) {
        die "Need faction for command $command\n" if !$faction;

        my %income = faction_income $faction;
        for my $currency (keys %income) {
            if ($income{$currency}) {
                command $faction, "+$income{$currency}$currency";
            }
        }
    } elsif ($command =~ /^score (.*)/) {
        my $setup = uc $1;
        @score_tiles = split /,/, $setup;
        die "Invalid scoring tile setup: $setup" if @score_tiles != 6;
    } else {
        die "Could not parse command '$command'.\n";
    }

    if ($type and $faction) {
        if ($factions{$faction}{$type} < 0) {
            die "Not enough '$type' in $faction after command '$command'\n";
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
        $prefix = ucfirst lc $1;
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

            $old_data{CULT} = $old_data{FIRE} +  $old_data{WATER} + $old_data{EARTH} + $old_data{AIR};
            $new_data{CULT} = $new_data{FIRE} +  $new_data{WATER} + $new_data{EARTH} + $new_data{AIR};

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

sub print_pretty {
    local *STDOUT = *STDERR;
    for (@factions) {
        my %f = %{$factions{$_}};

        print ucfirst $_, ":";
        print "  VP: $f{VP}";
        print "  Resources: $f{C}c / $f{W}w / $f{P}p, $f{P1}/$f{P2}/$f{P3} power";
        print "  Buildings: $f{D} D, $f{TP} TP, $f{TE} TE, $f{SH} SH, $f{SA} SA";
        print "  Cults: $f{FIRE} / $f{WATER} / $f{EARTH} / $f{AIR}";

        for (1..9) {
            if ($f{"BON$_"}) {
                print "  Bonus: $_";
            }
        }

        for (1..12) {
            if ($f{"FAV$_"}) {
                print "  Favor: $_";
            }
        }
    }

    for my $cult (@cults) {
        printf "%-8s", "$cult:";
        for (1..4) {
            my $key = "$cult$_";
            printf "%s / ", ($map{"$key"}{building} or ($_ == 1 ? 3 : 2));
        }
        print "";
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
        towns => \%towns,
        score_tiles => [map $score_tiles{$_}, @score_tiles], 
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

for my $faction (@factions) {
    $factions{$faction}{income} = { faction_income $faction };
    delete $factions{$faction}{buildings};
}

for (0..($turn-2)) {
    $score_tiles{$score_tiles[$_]}->{old} = 1;
}

current_score_tile->{active} = 1;
$score_tiles{$score_tiles[-1]}->{income_display} = '';

print_pretty;
print_json;

if (@error) {
    print STDERR $_ for @error;
    exit 1;
}
