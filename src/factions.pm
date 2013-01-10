#!/usr/bin/perl -wl

use strict;

use vars qw(%factions @factions %building_strength);
use Data::Dumper;

our %building_strength = (
    D => 1,
    TP => 2,
    TE => 2,
    SH => 3,
    SA => 3,
);

my %setups = (
    alchemists => { C => 15, W => 3, P1 => 5, P2 => 7,
                    WATER => 1, FIRE => 1, color => 'black',
                    ship => { 
                        level => 0, max_level => 3,
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
                    exchange_rates => {
                        C => { VP => 2 },
                        VP => { C => 2 }
                    },
                    buildings => {
                        D => { advance_cost => { W => 1, C => 2 },
                               income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                        TP => { advance_cost => { W => 2, C => 3 },
                                income => { C => [ 0, 2, 4, 7, 11 ],
                                            PW => [ 0, 1, 2, 3, 4 ] } },
                        TE => { advance_cost => { W => 2, C => 5 },
                                income => { P => [ 0, 1, 2, 3 ] } },
                        SH => { advance_cost => { W => 4, C => 6 },
                                advance_gain => [ { PW => 12 } ],
                                income => { C => [ 0, 6 ] } },
                        SA => { advance_cost => { W => 4, C => 6 },
                                income => { P => [ 0, 1 ] } },
                    }},
    darklings => { 
        C => 15, W => 1, P => 1, P1 => 5, P2 => 7,
        WATER => 1, EARTH => 1,
        color => 'black',
        ship => { 
            level => 0, max_level => 3,
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
            D => { advance_cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { advance_cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { advance_cost => { W => 2, C => 5 },
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { advance_cost => { W => 4, C => 6 },
                    advance_gain => [ { CONVERT_W_TO_P => 3 } ],
                    income => { PW => [ 0, 2 ] } },
            SA => { advance_cost => { W => 4, C => 10 },
                    income => { P => [ 0, 2 ] } },
        }
    },
    auren => { C => 15, W => 3, P1 => 5, P2 => 7,
               WATER => 1, AIR => 1,
               color => 'green',
               ship => { 
                   level => 0, max_level => 3,
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
                   D => { advance_cost => { W => 1, C => 2 },
                          income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                   TP => { advance_cost => { W => 2, C => 3 },
                           income => { C => [ 0, 2, 4, 6, 8 ],
                                       PW => [ 0, 1, 2, 4, 6 ] } },
                   TE => { advance_cost => { W => 2, C => 5 },
                           income => { P => [ 0, 1, 2, 3 ] } },
                   SH => { advance_cost => { W => 4, C => 6 },
                           advance_gain => [ { ACTA => 1, GAIN_FAVOR => 1 } ],
                           income => { PW => [ 0, 2 ] } },
                   SA => { advance_cost => { W => 4, C => 8 },
                           income => { P => [ 0, 1 ] } },
               }},
    witches => { C => 15, W => 3, P1 => 5, P2 => 7,
                 AIR => 2, color => 'green',
                 special => {
                     map(("TW$_", { VP => 5 }), 1..5)
                 },
                 ship => { 
                     level => 0, max_level => 3,
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
                     D => { advance_cost => { W => 1, C => 2 },
                            income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                     TP => { advance_cost => { W => 2, C => 3 },
                             income => { C => [ 0, 2, 4, 6, 8 ],
                                         PW => [ 0, 1, 2, 4, 6] } },
                     TE => { advance_cost => { W => 2, C => 5 },
                             income => { P => [ 0, 1, 2, 3 ] } },
                     SH => { advance_cost => { W => 4, C => 6 },
                             advance_gain => [ { ACTW => 1 } ],
                             income => { PW => [ 0, 2 ] } },
                     SA => { advance_cost => { W => 4, C => 6 },
                             income => { P => [ 0, 1 ] } },
             }},
    mermaids => { 
        C => 15, W => 3, P1 => 3, P2 => 9,
        WATER => 2,
        color => 'blue',
        ship => { 
            level => 1, max_level => 4,
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
            D => { advance_cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { advance_cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { advance_cost => { W => 2, C => 5 },
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { advance_cost => { W => 4, C => 6 },
                    advance_gain => [ { GAIN_SHIP => 1 } ],
                    income => { PW => [ 0, 4 ] } },
            SA => { advance_cost => { W => 4, C => 8 },
                    income => { P => [ 0, 1 ] } },
        }
    },
    swarmlings => { C => 20, W => 8, P1 => 3, P2 => 9,
                    FIRE => 1, EARTH => 1,
                    WATER => 1, AIR => 1, color => 'blue',
                    ship => { 
                        level => 0, max_level => 3,
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
                        D => { advance_cost => { W => 2, C => 3 },
                               income => { W => [ 2, 3, 4, 5, 6, 7, 8, 9, 9 ] } },
                        TP => { advance_cost => { W => 3, C => 4 },
                                income => { PW => [ 0, 2, 4, 6, 8 ],
                                            C => [ 0, 2, 4, 6, 9 ] } },
                        TE => { advance_cost => { W => 3, C => 6 },
                                income => { P => [ 0, 1, 2, 3 ] } },
                        SH => { advance_cost => { W => 5, C => 8 },
                                advance_gain => [ { ACTS => 1 } ],
                                income => { PW => [ 0, 4 ] } },
                        SA => { advance_cost => { W => 5, C => 8 },
                                income => { P => [ 0, 2 ] } },
                    }},
    nomads => { C => 15, W => 2, P1 => 5, P2 => 7,
                FIRE => 1, EARTH => 1, color => 'yellow',
                ship => { 
                    level => 0, max_level => 3,
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
                    D => { advance_cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { advance_cost => { W => 2, C => 3 },
                            income => { C => [ 0, 2, 4, 7, 11 ],
                                        PW => [ 0, 1, 2, 3, 4 ] } },
                    TE => { advance_cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { advance_cost => { W => 4, C => 8 },
                            advance_gain => [ { ACTN => 1 } ],
                            income => { PW => [ 0, 2 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    fakirs => { C => 15, W => 3, P1 => 7, P2 => 5,
                FIRE => 1, AIR => 1, color => 'yellow',
                ship => { 
                    level => 0, max_level => 0,
                },
                dig => {
                    level => 0, max_level => 1,
                    cost => [ { W => 3 }, { W => 2 } ],
                    advance_cost => { W => 2, C => 5, P => 1 },
                    advance_gain => [ { VP => 6 } ]
                },
                buildings => {
                    D => { advance_cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { advance_cost => { W => 2, C => 3 },
                            income => { C => [ 0, 2, 4, 6, 8 ],
                                        PW => [ 0, 1, 2, 4, 6 ] } },
                    TE => { advance_cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { advance_cost => { W => 4, C => 10 },
                            income => { P => [ 0, 1 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    engineers => { C => 10, W => 2, P1 => 3, P2 => 9, color => 'gray',
                   ship => { 
                       level => 0, max_level => 3,
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
                    D => { advance_cost => { W => 1, C => 1 },
                           income => { W => [ 0, 1, 2, 2, 3, 4, 4, 5, 6 ] } },
                    TP => { advance_cost => { W => 1, C => 2 },
                            income => { C => [ 0, 2, 4, 6, 8 ],
                                        PW => [ 0, 1, 2, 4, 6 ] } },
                    TE => { advance_cost => { W => 1, C => 4 },
                            income => { P => [ 0, 1, 1, 2 ],
                                        PW => [ 0, 0, 5, 5 ] } },
                    SH => { advance_cost => { W => 3, C => 6 },
                            income => { PW => [ 0, 2 ] } },
                    SA => { advance_cost => { W => 3, C => 6 },
                            income => { P => [ 0, 1 ] } },
               }},
    dwarves => { C => 15, W => 2, P3 => 5, P2 => 7,
                EARTH => 2, color => 'gray',
                ship => { 
                    level => 0, max_level => 0,
                },
                dig => {
                    level => 0, max_level => 2,
                    cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                    advance_cost => { W => 2, C => 5, P => 1 },
                    advance_gain => [ { VP => 6 }, { VP => 6 } ]
                },
                buildings => {
                    D => { advance_cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { advance_cost => { W => 2, C => 3 },
                            income => { C => [ 0, 3, 5, 7, 10 ],
                                        PW => [ 0, 1, 2, 4, 6 ] } },
                    TE => { advance_cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { advance_cost => { W => 4, C => 6 },
                            income => { PW => [ 0, 2 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    chaosmagicians => { 
        C => 15, W => 3, P1 => 5, P2 => 7,
        FIRE => 2,
        color => 'red',
        ship => { 
            level => 0, max_level => 3,
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
            D => { advance_cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { advance_cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { advance_cost => { W => 2, C => 5 },
                    advance_gain => [ { GAIN_FAVOR => 2 },
                                      { GAIN_FAVOR => 2 },
                                      { GAIN_FAVOR => 2 } ],
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { advance_cost => { W => 4, C => 4 },
                    advance_gain => [ { ACTC => 1 } ],
                    income => { W => [ 0, 2 ] } },
            SA => { advance_cost => { W => 4, C => 8 },
                    advance_gain => [ { GAIN_FAVOR => 2 } ],
                    income => { P => [ 0, 1 ] } },
        }
    },
    giants => { C => 15, W => 3, P1 => 5, P2 => 7,
                FIRE => 1, AIR => 1, color => 'red',
                ship => { 
                    level => 0, max_level => 3,
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
                    D => { advance_cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { advance_cost => { W => 2, C => 3 },
                            income => { C => [ 0, 2, 4, 6, 8 ],
                                        PW => [ 0, 1, 2, 4, 6] } },
                    TE => { advance_cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { advance_cost => { W => 4, C => 6 },
                            advance_gain => [ { ACTG => 1 } ],
                            income => { PW => [ 0, 4 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    mermaids => { 
        C => 15, W => 3, P1 => 3, P2 => 9,
        WATER => 2,
        color => 'blue',
        ship => { 
            level => 1, max_level => 4,
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
            D => { advance_cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { advance_cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { advance_cost => { W => 2, C => 5 },
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { advance_cost => { W => 4, C => 6 },
                    advance_gain => [ { GAIN_SHIP => 1 } ],
                    income => { PW => [ 0, 4 ] } },
            SA => { advance_cost => { W => 4, C => 8 },
                    income => { P => [ 0, 1 ] } },
        }
    },
    swarmlings => { C => 20, W => 8, P1 => 3, P2 => 9,
                    FIRE => 1, EARTH => 1,
                    WATER => 1, AIR => 1, color => 'blue',
                    ship => { 
                        level => 0, max_level => 3,
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
                        D => { advance_cost => { W => 2, C => 3 },
                               income => { W => [ 2, 3, 4, 5, 6, 7, 8, 9, 9 ] } },
                        TP => { advance_cost => { W => 3, C => 4 },
                                income => { PW => [ 0, 2, 4, 6, 8 ],
                                            C => [ 0, 2, 4, 6, 9 ] } },
                        TE => { advance_cost => { W => 3, C => 6 },
                                income => { P => [ 0, 1, 2, 3 ] } },
                        SH => { advance_cost => { W => 5, C => 8 },
                                advance_gain => [ { ACTS => 1 } ],
                                income => { PW => [ 0, 4 ] } },
                        SA => { advance_cost => { W => 5, C => 8 },
                                income => { P => [ 0, 2 ] } },
                    }},
    nomads => { C => 15, W => 2, P1 => 5, P2 => 7,
                FIRE => 1, EARTH => 1, color => 'yellow',
                ship => { 
                    level => 0, max_level => 3,
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
                    D => { advance_cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { advance_cost => { W => 2, C => 3 },
                            income => { C => [ 0, 2, 4, 7, 11 ],
                                        PW => [ 0, 1, 2, 3, 4 ] } },
                    TE => { advance_cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { advance_cost => { W => 4, C => 8 },
                            advance_gain => [ { ACTN => 1 } ],
                            income => { PW => [ 0, 2 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    fakirs => { C => 15, W => 3, P1 => 7, P2 => 5,
                FIRE => 1, AIR => 1, color => 'yellow',
                ship => { 
                    level => 0, max_level => 0,
                },
                dig => {
                    level => 0, max_level => 1,
                    cost => [ { W => 3 }, { W => 2 } ],
                    advance_cost => { W => 2, C => 5, P => 1 },
                    advance_gain => [ { VP => 6 } ]
                },
                buildings => {
                    D => { advance_cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { advance_cost => { W => 2, C => 3 },
                            income => { C => [ 0, 2, 4, 6, 8 ],
                                        PW => [ 0, 1, 2, 4, 6 ] } },
                    TE => { advance_cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { advance_cost => { W => 4, C => 10 },
                            income => { P => [ 0, 1 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    engineers => { C => 10, W => 2, P1 => 3, P2 => 9, color => 'gray',
                   ship => { 
                       level => 0, max_level => 3,
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
                    D => { advance_cost => { W => 1, C => 1 },
                           income => { W => [ 0, 1, 2, 2, 3, 4, 4, 5, 6 ] } },
                    TP => { advance_cost => { W => 1, C => 2 },
                            income => { C => [ 0, 2, 4, 6, 8 ],
                                        PW => [ 0, 1, 2, 4, 6 ] } },
                    TE => { advance_cost => { W => 1, C => 4 },
                            income => { P => [ 0, 1, 1, 2 ],
                                        PW => [ 0, 0, 5, 5 ] } },
                    SH => { advance_cost => { W => 3, C => 6 },
                            income => { PW => [ 0, 2 ] } },
                    SA => { advance_cost => { W => 3, C => 6 },
                            income => { P => [ 0, 1 ] } },
               }},
    dwarves => { C => 15, W => 2, P3 => 5, P2 => 7,
                EARTH => 2, color => 'gray',
                ship => { 
                    level => 0, max_level => 0,
                },
                dig => {
                    level => 0, max_level => 2,
                    cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                    advance_cost => { W => 2, C => 5, P => 1 },
                    advance_gain => [ { VP => 6 }, { VP => 6 } ]
                },
                buildings => {
                    D => { advance_cost => { W => 1, C => 2 },
                           income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                    TP => { advance_cost => { W => 2, C => 3 },
                            income => { C => [ 0, 3, 5, 7, 10 ],
                                        PW => [ 0, 1, 2, 4, 6 ] } },
                    TE => { advance_cost => { W => 2, C => 5 },
                            income => { P => [ 0, 1, 2, 3 ] } },
                    SH => { advance_cost => { W => 4, C => 6 },
                            income => { PW => [ 0, 2 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    chaosmagicians => { 
        C => 15, W => 3, P1 => 5, P2 => 7,
        FIRE => 2,
        color => 'red',
        ship => { 
            level => 0, max_level => 3,
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
            D => { advance_cost => { W => 1, C => 2 },
                   income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
            TP => { advance_cost => { W => 2, C => 3 },
                    income => { C => [ 0, 2, 4, 6, 8 ],
                                PW => [ 0, 1, 2, 4, 6 ] } },
            TE => { advance_cost => { W => 2, C => 5 },
                    advance_gain => [ { GAIN_FAVOR => 2 },
                                      { GAIN_FAVOR => 2 },
                                      { GAIN_FAVOR => 2 } ],
                    income => { P => [ 0, 1, 2, 3 ] } },
            SH => { advance_cost => { W => 4, C => 4 },
                    advance_gain => [ { ACTC => 1 } ],
                    income => { W => [ 0, 2 ] } },
            SA => { advance_cost => { W => 4, C => 8 },
                    advance_gain => [ { GAIN_FAVOR => 2 } ],
                    income => { P => [ 0, 1 ] } },
        }
    },
    halflings => { C => 15, W => 3, P1 => 3, P2 => 9,
                   EARTH => 1, AIR => 1, color => 'brown',
                   special => {
                       SHOVEL => 1
                   },
                   ship => { 
                       level => 0, max_level => 3,
                       advance_cost => { C => 4, P => 1 },
                       advance_gain => [ { VP => 2 },
                                         { VP => 3 },
                                         { VP => 4 } ]
                   },
                   dig => {
                       level => 0, max_level => 2,
                       cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                       advance_cost => { W => 2, C => 1, P => 1 },
                       advance_gain => [ { VP => 6 },
                                         { VP => 6 } ]
                   },
                   buildings => {
                       D => { advance_cost => { W => 1, C => 2 },
                              income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                       TP => { advance_cost => { W => 2, C => 3 },
                               income => { C => [ 0, 2, 4, 6, 8 ],
                                           PW => [ 0, 1, 2, 4, 6] } },
                       TE => { advance_cost => { W => 2, C => 5 },
                               income => { P => [ 0, 1, 2, 3 ] } },
                       SH => { advance_cost => { W => 4, C => 6 },
                               advance_gain => [ { SHOVEL => 3 } ],
                               income => { PW => [ 0, 2 ] } },
                       SA => { advance_cost => { W => 4, C => 6 },
                               income => { P => [ 0, 1 ] } },
               }},
    cultists => { C => 15, W => 3, P1 => 5, P2 => 7,
                  EARTH => 1, FIRE => 1, color => 'brown',
                  ship => { 
                      level => 0, max_level => 3,
                      advance_cost => { C => 4, P => 1 },
                      advance_gain => [ { VP => 2 },
                                        { VP => 3 },
                                        { VP => 4 } ]
                  },
                  dig => {
                      level => 0, max_level => 2,
                      cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                      advance_cost => { W => 2, C => 1, P => 1 },
                      advance_gain => [ { VP => 6 },
                                        { VP => 6 } ]
                  },
                   buildings => {
                       D => { advance_cost => { W => 1, C => 2 },
                              income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                       TP => { advance_cost => { W => 2, C => 3 },
                               income => { C => [ 0, 2, 4, 6, 8 ],
                                           PW => [ 0, 1, 2, 4, 6] } },
                       TE => { advance_cost => { W => 2, C => 5 },
                               income => { P => [ 0, 1, 2, 3 ] } },
                       SH => { advance_cost => { W => 4, C => 8 },
                               advance_gain => [ { VP => 7 } ],
                               income => { PW => [ 0, 2 ] } },
                       SA => { advance_cost => { W => 4, C => 8 },
                               income => { P => [ 0, 1 ] } },
               }},
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

    for (0..2) {
        $buildings->{TE}{advance_gain}[$_]{GAIN_FAVOR} ||= 1;
    }
    $buildings->{SA}{advance_gain}[0]{GAIN_FAVOR} ||= 1;

    for my $building (values %{$buildings}) {
        $building->{level} = 0;
    }

    $faction->{SHOVEL} = 0;

    push @factions, $faction_name;
}

1;
