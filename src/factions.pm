use strict;

use vars qw(%factions @factions);

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
                    gain => { CONVERT_W_TO_P => 3 },
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

sub setup {
    my $faction_name = lc shift;

    die "Unknown faction: $faction_name\n" if !$setups{$faction_name};

    my $faction = $factions{$faction_name} = $setups{$faction_name};    

    $faction->{P} ||= 0;
    $faction->{P1} ||= 0;
    $faction->{P2} ||= 0;
    $faction->{P3} ||= 0;

    my @cults = qw(EARTH FIRE WATER AIR);
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

1;
