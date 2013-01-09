use strict;

use vars qw(%factions @factions);
use Data::Dumper;

my %setups = (
    alchemists => { C => 15, W => 3, P1 => 5, P2 => 7,
                    WATER => 1, FIRE => 1, color => 'black',
                    ship => { 
                        level => 0, max_level => 4,
                        advance_cost => { C => 4, P => 1 },
                        advance_gain => [ { VP => 2 },
                                          { VP => 3 },
                                          { VP => 4 } ]
                    },
                    dig => {
                        level => 0, max_level => 2,
                        cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                        advance_cost => { W => 2, C => 5, P => 1 },
                        advance_gain => [ { VP => 6 },
                                          { VP => 6 } ]
                    },
                    special => {
                        SHOVEL => { PW => 2 },
                        enable_if => { SH => 1 },
                    },
                    buildings => {
                        D => { cost => { W => 1, C => 2 },
                               income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                        TP => { cost => { W => 2, C => 3 },
                                income => { C => [ 0, 2, 4, 7, 11 ],
                                            PW => [ 0, 1, 2, 3, 4 ] } },
                        TE => { cost => { W => 2, C => 5 },
                                income => { P => [ 0, 1, 2, 3 ] } },
                        SH => { cost => { W => 4, C => 6 },
                                advance_gain => [ { PW => 12 } ],
                                income => { C => [ 0, 6 ] } },
                        SA => { cost => { W => 4, C => 6 },
                                income => { P => [ 0, 1 ] } },
                    }},
    darklings => { 
        C => 15, W => 1, P => 1, P1 => 5, P2 => 7,
        WATER => 1, EARTH => 1,
        color => 'black',
        ship => { 
            level => 0, max_level => 4,
            advance_cost => { C => 4, P => 1 },
            advance_gain => [ { VP => 2 },
                              { VP => 3 },
                              { VP => 4 } ]
        },
        dig => {
            level => 0, max_level => 0,
            cost => [ { P => 1 } ],
            gain => [ { VP => 2 } ],
        },
        buildings => {
            D => { cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { cost => { W => 2, C => 5 },
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { cost => { W => 4, C => 6 },
                    advance_gain => [ { CONVERT_W_TO_P => 3 } ],
                    income => { PW => [ 0, 2 ] } },
            SA => { cost => { W => 4, C => 10 },
                    income => { P => [ 0, 2 ] } },
        }
    },
    auren => { C => 15, W => 3, P1 => 5, P2 => 7,
               WATER => 1, AIR => 1,
               color => 'green',
               ship => { 
                   level => 0, max_level => 4,
                   advance_cost => { C => 4, P => 1 },
                   advance_gain => [ { VP => 2 },
                                     { VP => 3 },
                                     { VP => 4 } ]
               },
               dig => {
                   level => 0, max_level => 2,
                   cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                   advance_cost => { W => 2, C => 5, P => 1 },
                   advance_gain => [ { VP => 6 },
                                     { VP => 6 } ]
               },
               buildings => {
                   D => { cost => { W => 1, C => 2 },
                          income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                   TP => { cost => { W => 2, C => 3 },
                           income => { C => [ 0, 2, 4, 6, 8 ],
                                       PW => [ 0, 1, 2, 4, 6 ] } },
                   TE => { cost => { W => 2, C => 5 },
                           income => { P => [ 0, 1, 2, 3 ] } },
                   SH => { cost => { W => 4, C => 6 },
                           advance_gain => [ { ACTA => 1, GAIN_FAVOR => 1 } ],
                           income => { PW => [ 0, 2 ] } },
                   SA => { cost => { W => 4, C => 8 },
                           income => { P => [ 0, 1 ] } },
               }},
    mermaids => { 
        C => 15, W => 3, P1 => 3, P2 => 9,
        WATER => 2,
        color => 'blue',
        ship => { 
            level => 1, max_level => 5,
            advance_cost => { C => 4, P => 1 },
            advance_gain => [ { VP => 0 },
                              { VP => 2 },
                              { VP => 3 },
                              { VP => 4 },
                              { VP => 5 } ]
        },
        dig => {
            level => 0, max_level => 2,
            cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
            advance_cost => { W => 2, C => 5, P => 1 },
            advance_gain => [ { VP => 6 },
                              { VP => 6 } ]
        },
        buildings => {
            D => { cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { cost => { W => 2, C => 5 },
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { cost => { W => 4, C => 6 },
                    advance_gain => [ { GAIN_SHIP => 1 } ],
                    income => { PW => [ 0, 4 ] } },
            SA => { cost => { W => 4, C => 8 },
                    income => { P => [ 0, 1 ] } },
        }
    },
    swarmlings => { C => 20, W => 8, P1 => 3, P2 => 9,
                    FIRE => 1, EARTH => 1,
                    WATER => 1, AIR => 1, color => 'blue',
                    ship => { 
                        level => 0, max_level => 4,
                        advance_cost => { C => 4, P => 1 },
                        advance_gain => [ { VP => 2 },
                                          { VP => 3 },
                                          { VP => 4 } ]
                    },
                    dig => {
                        level => 0, max_level => 2,
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
                               income => { W => [ 2, 3, 4, 5, 6, 7, 8, 9, 9 ] } },
                        TP => { cost => { W => 3, C => 4 },
                                income => { PW => [ 0, 2, 4, 6, 8 ],
                                            C => [ 0, 2, 4, 6, 9 ] } },
                        TE => { cost => { W => 3, C => 6 },
                                income => { P => [ 0, 1, 2, 3 ] } },
                        SH => { cost => { W => 5, C => 8 },
                                advance_gain => [ { ACTS => 1 } ],
                                income => { PW => [ 0, 4 ] } },
                        SA => { cost => { W => 5, C => 8 },
                                income => { P => [ 0, 2 ] } },
                    }},
    nomads => { C => 15, W => 2, P1 => 5, P2 => 7,
                FIRE => 1, EARTH => 1, color => 'yellow',
                ship => { 
                    level => 0, max_level => 4,
                    advance_cost => { C => 4, P => 1 },
                    advance_gain => [ { VP => 2 },
                                      { VP => 3 },
                                      { VP => 4 } ]
                },
                dig => {
                    level => 0, max_level => 2,
                    cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                    advance_cost => { W => 2, C => 5, P => 1 },
                    advance_gain => [ { VP => 6 },
                                      { VP => 6 } ]
                },
                buildings => {
                    D => { cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { cost => { W => 2, C => 3 },
                            income => { C => [ 0, 2, 4, 7, 11 ],
                                        PW => [ 0, 1, 2, 3, 4 ] } },
                    TE => { cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { cost => { W => 4, C => 8 },
                            advance_gain => [ { ACTN => 1 } ],
                            income => { PW => [ 0, 2 ] } },
                    SA => { cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    engineers => { C => 10, W => 2, P1 => 3, P2 => 9, color => 'gray',
                   ship => { 
                       level => 0, max_level => 4,
                       advance_cost => { C => 4, P => 1 },
                       advance_gain => [ { VP => 2 },
                                         { VP => 3 },
                                         { VP => 4 } ]
                   },
                   dig => {
                       level => 0, max_level => 2,
                       cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                       advance_cost => { W => 2, C => 5, P => 1 },
                       advance_gain => [ { VP => 6 },
                                         { VP => 6 } ]
                   },
                   buildings => {
                    D => { cost => { W => 1, C => 1 },
                           income => { W => [ 0, 1, 2, 2, 3, 4, 4, 5, 6 ] } },
                    TP => { cost => { W => 1, C => 2 },
                            income => { C => [ 0, 2, 4, 6, 8 ],
                                        PW => [ 0, 1, 2, 4, 6 ] } },
                    TE => { cost => { W => 1, C => 4 },
                            income => { P => [ 0, 1, 1, 2 ],
                                        PW => [ 0, 0, 5, 5 ] } },
                    SH => { cost => { W => 3, C => 6 },
                            income => { PW => [ 0, 2 ] } },
                    SA => { cost => { W => 3, C => 6 },
                            income => { P => [ 0, 1 ] } },
               }},
    chaosmagicians => { 
        C => 15, W => 3, P1 => 5, P2 => 7,
        FIRE => 2,
        color => 'red',
        ship => { 
            level => 0, max_level => 4,
            advance_cost => { C => 4, P => 1 },
            advance_gain => [ { VP => 2 },
                              { VP => 3 },
                              { VP => 4 } ]
        },
        dig => {
            level => 0, max_level => 2,
            cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
            advance_cost => { W => 2, C => 5, P => 1 },
            advance_gain => [ { VP => 6 },
                              { VP => 6 } ]
        },
        buildings => {
            D => { cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { cost => { W => 2, C => 5 },
                    advance_gain => [ { GAIN_FAVOR => 2 },
                                      { GAIN_FAVOR => 2 },
                                      { GAIN_FAVOR => 2 } ],
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { cost => { W => 4, C => 4 },
                    advance_gain => [ { ACTC => 1 } ],
                    income => { W => [ 0, 2 ] } },
            SA => { cost => { W => 4, C => 8 },
                    advance_gain => [ { GAIN_FAVOR => 2 } ],
                    income => { P => [ 0, 1 ] } },
        }
    },
);

sub setup {
    my $faction_name = lc shift;

    die "Unknown faction: $faction_name\n" if !$setups{$faction_name};

    my $faction = $factions{$faction_name} = $setups{$faction_name};    

    $faction->{P} ||= 0;
    $faction->{P1} ||= 0;
    $faction->{P2} ||= 0;
    $faction->{P3} ||= 0;

    $faction->{VP} = 20;

    my @cults = qw(EARTH FIRE WATER AIR);
    for (@cults) {
        $faction->{$_} ||= 0;
    }

    my $buildings = $faction->{buildings};
    $buildings->{D}{max_level} = 8;
    $buildings->{TP}{max_level} = 4;
    $buildings->{SH}{max_level} = 1;
    $buildings->{TE}{max_level} = 3;
    $buildings->{SA}{max_level} = 1;
    $buildings->{VP}{max_level} = 20;

    for (0..2) {
        $buildings->{TE}{advance_gain}[$_]{GAIN_FAVOR} ||= 1;
    }
    $buildings->{SA}{advance_gain}[0]{GAIN_FAVOR} ||= 1;

    for my $building (values %{$buildings}) {
        $building->{level} = 0;
        $building->{advance_cost} = $building->{cost};
    }

    $faction->{SHOVEL} = 0;

    push @factions, $faction_name;
}

1;
