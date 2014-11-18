package Game::Constants;

use Exporter::Easy (EXPORT => [ '@cults',
                                '%actions',
                                '%building_aliases',
                                '%building_strength',
                                '@colors',
                                '%colors',
                                '%faction_setups',
                                '%faction_setups_extra',
                                '@base_map',
                                '%resource_aliases',
                                '%tiles',
                                '%final_scoring' ]);

use strict;
use Readonly;

## Cults

Readonly our @cults => qw(FIRE WATER EARTH AIR);

## Buildings

Readonly our %building_strength => (
    D => 1,
    TP => 2,
    TE => 2,
    SH => 3,
    SA => 3,
);

Readonly our %building_aliases => (
    DWELLING => 'D',
    'TRADING POST' => 'TP',
    TEMPLE => 'TE',
    STRONGHOLD => 'SH',
    SANCTUARY => 'SA',
);

## Resources

Readonly our %resource_aliases => (
    PRIEST => 'P',
    PRIESTS => 'P',
    POWER => 'PW',
    WORKER => 'W',
    WORKERS => 'W',
    COIN => 'C',
    COINS => 'C',
);

## Tiles

Readonly our %actions => (
    ACT1 => { cost => { PW => 3 }, gain => { BRIDGE => 1 },
              subaction => { 'bridge' => 1 }},
    ACT2 => { cost => { PW => 3 }, gain => { P => 1 } },
    ACT3 => { cost => { PW => 4 }, gain => { W => 2 } },
    ACT4 => { cost => { PW => 4 }, gain => { C => 7 } },
    ACT5 => { cost => { PW => 4 },
              gain => { SPADE => 1 },
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    ACT6 => { cost => { PW => 6 }, gain => { SPADE => 2 },
              subaction => { dig => 1, 'transform' => 2, 'build' => 1} },
    ACTA => { cost => {}, gain => { CULT => 2 , CULTS_ON_SAME_TRACK => 1 } },
    ACTE => { dont_block => 1,
              cost => { W => 2 }, gain => { BRIDGE => 1 },
              subaction => { bridge => 1 } },
    ACTG => { cost => {}, gain => { SPADE => 2},
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    ACTS => { cost => {}, gain => { FREE_TP => 1 },
              subaction => { 'upgrade' => 1 }},
    ACTN => { cost => {}, gain => { FREE_TF => 1, TF_NEED_HEX_ADJACENCY => 1 },
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    ACTW => { cost => {}, gain => { FREE_D => 1, TELEPORT_NO_TF => 1 },
              subaction => { 'build' => 1 } },
    ACTC => { cost => {}, gain => { GAIN_ACTION => 2 } },
    ACTH1 => { dont_block => 1,
               cost => { PW => 3 },
               gain => { PICK_COLOR => 1, 
                         VP => 2 } },
    ACTH2 => { dont_block => 1,
               cost => { PW_TOKEN => 3 },
               gain => { PICK_COLOR => 1, 
                         VP => 2 } },
    BON1 => { cost => {}, gain => { SPADE => 1 },
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    BON2 => { cost => {}, gain => { CULT => 1 } },
    FAV6 => { cost => {}, gain => { CULT => 1 } },
);
my @power_action_names =  map { "ACT$_" } 1..6;
       
sub init_tiles {
    my %tiles = @_;

    for my $tile_name (keys %tiles) {
        my $tile = $tiles{$tile_name};
        if ($tile_name =~ /^SCORE/) {
            my $currency = (keys %{$tile->{income}})[0];
            $tile->{income_display} =
                sprintf("%d %s -> %d %s", $tile->{req}, $tile->{cult},
                        $tile->{income}{$currency}, $currency);
        }
        if (exists $actions{$tile_name}) {
            $tile->{action} = $actions{$tile_name};
        }
    }

    %tiles;
}

Readonly our %tiles => init_tiles (
    BON1 => { income => { C => 2 } },
    BON2 => { income => { C => 4 } },
    BON3 => { income => { C => 6 } },
    BON4 => { income => { PW => 3 }, special => { ship => 1 } },
    BON5 => { income => { PW => 3, W => 1 } },
    BON6 => { income => { W => 2 },
              pass_vp => { SA => [0, 4], SH => [0, 4] } },
    BON7 => { income => { W => 1 },
              pass_vp => { TP => [ map { $_ * 2 } 0..4 ] } },
    BON8 => { income => { P => 1 } },
    BON9 => { income => { C => 2 },
              pass_vp => { D => [ map { $_ } 0..8 ] } },
    BON10 => { income => { PW => 3 },
               pass_vp => { ship => [ map { $_ * 3 } 0..5 ] },
               option => 'shipping-bonus' },

    FAV1 => { gain => { FIRE => 3 }, income => {}, count => 1 },
    FAV2 => { gain => { WATER => 3 }, income => {}, count => 1 },
    FAV3 => { gain => { EARTH => 3 }, income => {}, count => 1 },
    FAV4 => { gain => { AIR => 3 }, income => {}, count => 1 },

    FAV5 => { gain => { FIRE => 2, TOWN_SIZE => -1 }, income => {} },
    FAV6 => { gain => { WATER => 2 }, income => {} },
    FAV7 => { gain => { EARTH => 2 }, income => { W => 1, PW => 1} },
    FAV8 => { gain => { AIR => 2 }, income => { PW => 4} },

    FAV9 => { gain => { FIRE => 1 }, income => { C => 3} },
    FAV10 => { gain => { WATER => 1 }, income => {}, vp => { TP => 3 } },
    FAV11 => { gain => { EARTH => 1 }, income => {}, vp => { D => 2 } },
    FAV12 => { gain => { AIR => 1 }, income => {},
               pass_vp => { TP => [ 0, 2, 3, 3, 4 ] } },

    SCORE1 => { vp => { SPADE => 2 },
                vp_display => 'SPADE >> 2',
                vp_mode => 'gain',
                cult => 'EARTH',
                req => 1, 
                income => { C => 1 } },
    SCORE2 => { vp => { map(("TW$_", 5), 1..8) },
                vp_display => 'TOWN >> 5',
                vp_mode => 'gain',
                cult => 'EARTH',
                req => 4, 
                income => { SPADE => 1 } },
    SCORE3 => { vp => { D => 2 },
                vp_display => 'D >> 2',
                vp_mode => 'build',
                cult => 'WATER',
                req => 4, 
                income => { P => 1 } },    
    SCORE4 => { vp => { SA => 5, SH => 5 },
                vp_display => 'SA/SH >> 5',
                vp_mode => 'build',
                cult => 'FIRE',
                req => 2,
                income => { W => 1 } },    
    SCORE5 => { vp => { D => 2 },
                vp_display => 'D >> 2',
                vp_mode => 'build',
                cult => 'FIRE',
                req => 4, 
                income => { PW => 4 } },    
    SCORE6 => { vp => { TP => 3 },
                vp_display => 'TP >> 3',
                vp_mode => 'build',
                cult => 'WATER',
                req => 4, 
                income => { SPADE => 1 } },    
    SCORE7 => { vp => { SA => 5, SH => 5 },
                vp_display => 'SA/SH >> 5',
                vp_mode => 'build',
                cult => 'AIR',
                req => 2,
                income => { W => 1 } },    
    SCORE8 => { vp => { TP => 3 },
                vp_display => 'TP >> 3',
                vp_mode => 'build',
                cult => 'AIR',
                req => 4, 
                income => { SPADE => 1 } },    

    TW1 => { gain => { KEY => 1, VP => 5, C => 6 } },
    TW2 => { gain => { KEY => 1, VP => 7, W => 2 } },
    TW3 => { gain => { KEY => 1, VP => 9, P => 1 } },
    TW4 => { gain => { KEY => 1, VP => 6, PW => 8 } },
    TW5 => { gain => { KEY => 1, VP => 8, FIRE => 1, WATER => 1, EARTH => 1, AIR => 1 } },
    TW6 => { gain => { KEY => 2, VP => 2, FIRE => 2, WATER => 2, EARTH => 2, AIR => 2 }, count => 1, option => 'mini-expansion-1' },
    TW7 => { gain => { KEY => 1, VP => 4, GAIN_SHIP => 1, carpet_range => 1 },
             option => 'mini-expansion-1' },
    TW8 => { gain => { KEY => 1, VP => 11 }, count => 1, option => 'mini-expansion-1' },
);

## Initial game board

Readonly our @base_map =>
    qw(brown gray green blue yellow red brown black red green blue red black E
       yellow x x brown black x x yellow black x x yellow E
       x x black x gray x green x green x gray x x E
       green blue yellow x x red blue x red x red brown E
       black brown red blue black brown gray yellow x x green black blue E
       gray green x x yellow green x x x brown gray brown E
       x x x gray x red x green x yellow black blue yellow E
       yellow blue brown x x x blue black x gray brown gray E
       red black gray blue red green yellow brown gray x blue green red E);

# The terraforming color wheel.
Readonly our @colors => qw(yellow brown black blue green gray red);
Readonly our %colors => map { ($colors[$_], $_) } 0..$#colors;

## Faction definitions
Readonly our %faction_setups => (
    alchemists => { C => 15, W => 3, P1 => 5, P2 => 7,
                    WATER => 1, FIRE => 1, color => 'black',
                    display => "Alchemists",
                    faction_board_id => 11,
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
                        SPADE => { PW => 2 },
                        enable_if => { SH => 1 },
                        mode => 'gain',
                    },
                    exchange_rates => {
                        C => { VP => 2 },
                        VP => { C => 1 }
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
        display => "Darklings",
        faction_board_id => 12,
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
            gain => [ { SPADE => 1, VP => 2 } ],
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
               display => "Auren",
               faction_board_id => 13,
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
                     mode => 'gain',
                     map(("TW$_", { VP => 5 }), 1..8)
                 },
                 display => "Witches",
                 faction_board_id => 14,
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
        display => "Mermaids",
        faction_board_id => 6,
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
                    display => "Swarmlings",
                    faction_board_id => 5,
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
                        mode => 'gain',
                        map(("TW$_", { W => 3 }), 1..8)
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
                display => "Nomads",
                faction_board_id => 2,
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
                display => "Fakirs",
                faction_board_id => 1,
                ship => { 
                    level => 0, max_level => 0,
                },
                teleport => {
                    level => 0, max_level => 1,
                    type => 'carpet',
                    cost => [ { P => 1 }, { P => 1 } ],
                    gain => [ { VP => 4 }, { VP => 4 } ],
                    advance_gain => [ { carpet_range => 1 } ],
                },
                carpet_range => 1,
                carpet_max_range => 4,
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
                            advance_gain => [ { GAIN_TELEPORT => 1 } ],
                            income => { P => [ 0, 1 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    engineers => { C => 10, W => 2, P1 => 3, P2 => 9, color => 'gray',
                   display => "Engineers",
                   faction_board_id => 8,
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
                   ACTE => 1,
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
    dwarves => { C => 15, W => 3, P1 => 5, P2 => 7,
                EARTH => 2, color => 'gray',
                display => "Dwarves",
                faction_board_id => 7,
                ship => { 
                    level => 0, max_level => 0,
                },
                teleport => {
                    level => 0, max_level => 1,
                    type => 'tunnel',
                    cost => [ { W => 2 }, { W => 1 } ],
                    gain => [ { VP => 4 }, { VP => 4 } ],
                },
                tunnel_range => 1,
                tunnel_max_range => 1,
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
                            advance_gain => [ { GAIN_TELEPORT => 1 } ],
                            income => { PW => [ 0, 2 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    chaosmagicians => { 
        C => 15, W => 4, P1 => 5, P2 => 7,
        FIRE => 2,
        color => 'red',
        display => "Chaos Magicians",
        faction_board_id => 3,
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
                display => "Giants",
                faction_board_id => 4,
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
    halflings => { C => 15, W => 3, P1 => 3, P2 => 9,
                   EARTH => 1, AIR => 1, color => 'brown',
                   display => "Halflings",
                   faction_board_id => 9,
                   special => {
                       mode => 'gain',
                       SPADE => { VP => 1 }
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
                       SH => { advance_cost => { W => 4, C => 8 },
                               advance_gain => [ { SPADE => 3 } ],
                               subactions => {
                                   transform => 3,
                                   build => 1,
                               },
                               income => { PW => [ 0, 2 ] } },
                       SA => { advance_cost => { W => 4, C => 6 },
                               income => { P => [ 0, 1 ] } },
               }},
    cultists => { C => 15, W => 3, P1 => 5, P2 => 7,
                  EARTH => 1, FIRE => 1, color => 'brown',
                  display => "Cultists",
                  faction_board_id => 10,
                  ship => { 
                      level => 0, max_level => 3,
                      advance_cost => { C => 4, P => 1 },
                      advance_gain => [ { VP => 2 },
                                        { VP => 3 },
                                        { VP => 4 } ]
                  },
                  leech_effect => {
                      taken => {
                          CULT => 1,
                      },
                      not_taken => {
                          PW => 1,
                      },
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
                       SH => { advance_cost => { W => 4, C => 8 },
                               advance_gain => [ { VP => 7 } ],
                               income => { PW => [ 0, 2 ] } },
                       SA => { advance_cost => { W => 4, C => 8 },
                               income => { P => [ 0, 1 ] } },
               }},
);

Readonly our %faction_setups_extra => (
    playtest_v1_ice => {
        'icemaidens' => {
            C => 15, W => 3, P1 => 6, P2 => 6,
            GAIN_FAVOR => 1,
            PICK_COLOR => 1,
            WATER => 1, AIR => 1,
            color => 'ice',
            secondary_color => undef,
            display => "Ice Maidens",
            faction_board_id => undef,
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 }, { VP => 3 }, { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 2,
                cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                advance_cost => { C => 5, P => 1 },
                advance_gain => [ { VP => 6 },
                                  { VP => 6 } ],
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 6 },
                        pass_vp => [
                            {},
                            { TE => [0, 3, 6, 9] }
                            ],
                        income => { PW => [ 0, 4 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},
        'yetis' => {
            C => 15, W => 3, P1 => 0, P2 => 12,
            PICK_COLOR => 1,
            EARTH => 1, AIR => 1,
            discount => {
                (map { ($_ => { PW => 1 }) } @power_action_names),
            },
            color => 'ice',
            secondary_color => undef,
            display => "Yetis",
            faction_board_id => undef,
            building_strength => {
                SH => 4,
                SA => 4,
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 },
                                  { VP => 3 },
                                  { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 2,
                cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                advance_cost => { W => 1, C => 5, P => 1 },
                advance_gain => [ { VP => 6 },
                                  { VP => 6 } ],
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 2, 4, 6, 8 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 6 },
                        advance_gain => [ {
                            allow_reuse => {
                                (map { ($_ => 1) } @power_action_names),
                            }} ],
                        income => { PW => [ 0, 4 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},
    },
    final_ice => {
        'icemaidens' => {
            C => 15, W => 3, P1 => 6, P2 => 6,
            GAIN_FAVOR => 1,
            PICK_COLOR => 1,
            WATER => 1, AIR => 1,
            color => 'ice',
            secondary_color => undef,
            display => "Ice Maidens",
            faction_board_id => undef,
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 }, { VP => 3 }, { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 2,
                cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                advance_cost => { C => 5, W => 1, P => 1 },
                advance_gain => [ { VP => 6 },
                                  { VP => 6 } ],
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 6 },
                        pass_vp => [
                            {},
                            { TE => [0, 3, 6, 9] }
                            ],
                        income => { PW => [ 0, 4 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},
        'yetis' => {
            C => 15, W => 3, P1 => 0, P2 => 12,
            PICK_COLOR => 1,
            EARTH => 1, AIR => 1,
            discount => {
                (map { ($_ => { PW => 1 }) } @power_action_names),
            },
            color => 'ice',
            secondary_color => undef,
            display => "Yetis",
            faction_board_id => undef,
            building_strength => {
                SH => 4,
                SA => 4,
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 },
                                  { VP => 3 },
                                  { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 2,
                cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
                advance_cost => { W => 1, C => 5, P => 1 },
                advance_gain => [ { VP => 6 },
                                  { VP => 6 } ],
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 2, 4, 6, 8 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 6 },
                        advance_gain => [ {
                            allow_reuse => {
                                (map { ($_ => 1) } @power_action_names),
                            }} ],
                        income => { PW => [ 0, 4 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},
    },
    playtest_v1_volcano => {
        'acolytes' => {
            C => 15, W => 4, P1 => 6, P2 => 6,
            FIRE => 3, WATER => 3, EARTH => 3, AIR => 3,
            color => 'volcano',
            secondary_color => undef,
            display => "Acolytes (v1)",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, CULT => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 }, { VP => 3 }, { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            volcano_effect => {
                not_home => { LOSE_CULT => 3 },
                home => { LOSE_CULT => 4 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 0, 1, 2, 3, 4, 5, 6, 7, 7 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { PRIEST_CULT_BONUS => 1 } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 8 },
                        income => { P => [ 0, 1 ] } },
            }},
        'dragonlords' => {
            C => 15, W => 2, P1 => 4, P2 => 4,
            FIRE => 2,
            color => 'volcano',
            secondary_color=> undef,
            display => "Dragon Masters (v1)",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, P1 => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 },
                                  { VP => 3 },
                                  { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            volcano_effect => {
                not_home => { LOSE_PW_TOKEN => 1 },
                home => { LOSE_PW_TOKEN => 2 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 1, 2, 3, 4, 4, 5, 6, 7, 7 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { P1 => 'PLAYER_COUNT' } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 8 },
                        income => { P => [ 0, 1 ] } },
            }},
    },
    playtest_v2_volcano => {
        'acolytes' => {
            C => 15, W => 4, P1 => 6, P2 => 6,
            FIRE => 3, WATER => 3, EARTH => 3, AIR => 3,
            color => 'volcano',
            secondary_color => undef,
            display => "Acolytes (v2)",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, CULT => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 }, { VP => 3 }, { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            volcano_effect => {
                not_home => { LOSE_CULT => 3 },
                home => { LOSE_CULT => 4 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 0, 1, 2, 3, 3, 4, 5, 6, 6 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { PRIEST_CULT_BONUS => 1 } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 8 },
                        income => { P => [ 0, 1 ] } },
            }},
        'dragonlords' => {
            C => 15, W => 3, P1 => 4, P2 => 4,
            FIRE => 2,
            color => 'volcano',
            secondary_color=> undef,
            display => "Dragon Masters (v2)",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, P1 => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 },
                                  { VP => 3 },
                                  { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            volcano_effect => {
                not_home => { LOSE_PW_TOKEN => 1 },
                home => { LOSE_PW_TOKEN => 2 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 0, 1, 2, 3, 3, 4, 5, 6, 6 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { P1 => 'PLAYER_COUNT' } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},
    },
    playtest_v3_volcano => {
        'acolytes' => {
            C => 15, W => 3, P1 => 6, P2 => 6,
            FIRE => 3, WATER => 3, EARTH => 3, AIR => 3,
            color => 'volcano',
            secondary_color => undef,
            display => "Acolytes (v3)",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, CULT => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 }, { VP => 3 }, { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            volcano_effect => {
                not_home => { LOSE_CULT => 3 },
                home => { LOSE_CULT => 4 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 0, 1, 2, 3, 3, 4, 5, 6, 6 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { PRIEST_CULT_BONUS => 1 } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 8 },
                        income => { P => [ 0, 1 ] } },
            }},
        'dragonlords' => {
            C => 15, W => 3, P1 => 4, P2 => 4,
            FIRE => 2,
            color => 'volcano',
            secondary_color=> undef,
            display => "Dragon Masters (v2)",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, P1 => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 },
                                  { VP => 3 },
                                  { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            volcano_effect => {
                not_home => { LOSE_PW_TOKEN => 1 },
                home => { LOSE_PW_TOKEN => 2 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 0, 1, 2, 3, 3, 4, 5, 6, 6 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { P1 => 'PLAYER_COUNT' } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},
    },
    final_volcano => {
        'acolytes' => {
            C => 15, W => 3, P1 => 6, P2 => 6,
            FIRE => 3, WATER => 3, EARTH => 3, AIR => 3,
            color => 'volcano',
            secondary_color => undef,
            display => "Acolytes",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, CULT => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 }, { VP => 3 }, { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            action => {
                BON1 => { subaction => { } },
                ACT5 => { subaction => { } },
                ACT6 => { subaction => { } },
            },
            volcano_effect => {
                not_home => { LOSE_CULT => 3 },
                home => { LOSE_CULT => 4 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 0, 1, 2, 3, 3, 4, 5, 6, 6 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { PRIEST_CULT_BONUS => 1 } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 8 },
                        income => { P => [ 0, 1 ] } },
            }},
        'dragonlords' => {
            C => 15, W => 3, P1 => 4, P2 => 4,
            FIRE => 2,
            color => 'volcano',
            secondary_color=> undef,
            display => "Dragonlords",
            faction_board_id => undef,
            post_setup => {
                PICK_COLOR => 1,
            },
            special => {
                SPADE => { SPADE => -1, P1 => 1 },
                mode => 'gain',
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 },
                                  { VP => 3 },
                                  { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { } ],
                gain => [ { VOLCANO_TF => 1 } ],
            },
            action => {
                BON1 => { subaction => { } },
                ACT5 => { subaction => { } },
                ACT6 => { subaction => { } },
            },
            volcano_effect => {
                not_home => { LOSE_PW_TOKEN => 1 },
                home => { LOSE_PW_TOKEN => 2 },
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 0, 1, 2, 3, 3, 4, 5, 6, 6 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 4, C => 8 },
                        advance_gain => [ { P1 => 'PLAYER_COUNT' } ],
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 8 },
                        income => { P => [ 0, 1 ] } },
            }},
    },

    final_variable => {
        'shapeshifters' => {
            C => 15, W => 3, P1 => 4, P2 => 4,
            FIRE => 1, WATER => 1,
            color => 'variable',
            board => 'variable',
            display => "Shapeshifters",
            faction_board_id => undef,
            PICK_COLOR => 1,
            pick_color_field => 'color',
            leech_effect => {
                taken => {
                    P3 => 1,
                },
                not_taken => {
                    PW => 1,
                },
            },
            ship => {
                level => 0, max_level => 3,
                advance_cost => { C => 4, P => 1 },
                advance_gain => [ { VP => 2 }, { VP => 3 }, { VP => 4 } ],
            },
            dig => {
                level => 0, max_level => 0,
                cost => [ { W => 3 } ],
                gain => [ { SPADE => 1 } ],
            },
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 1, 2, 3, 4, 5, 6, 7, 8, 8 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 2, 3 ] } },
                SH => { advance_cost => { W => 3, C => 6 },
                        advance_gain => [ { ACTH1 => 1, ACTH2 => 1 } ],
                        income => { PW => [ 0, 4 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},

        'riverwalkers' => {
            C => 15, W => 3, P1 => 10, P2 => 2,
            FIRE => 1, AIR => 1, MAX_P => 1,
            color => 'variable',
            board => 'variable',
            display => "Riverwalkers",
            faction_board_id => undef,
            PICK_COLOR => 1,
            pick_color_field => 'color',
            adjacency => {
                direct => 0,
            },
            ship => {
                level => 1, max_level => 1,
            },
            locked_terrain => {
                'gain-priest' => { gain => { P => 1 }, permanent => 1 },
                map { 
                    ($_, { gain => { MAX_P => 1 } })
                } qw(yellow brown black blue green gray red),
            },
            # Immediately lose any spades that are gained
            special => {
                SPADE => { },
                P => { UNLOCK_TERRAIN => 1 },
                mode => 'replace',
            }, 
            # Can't take a spade-producing special action
            action => {
                BON1 => { forbid => 1 },
                ACT5 => { forbid => 1 },
                ACT6 => { forbid => 1 },
            },
            # no explicit dig action
            buildings => {
                D => { advance_cost => { W => 1, C => 2 },
                       income => { W => [ 1, 2, 3, 3, 4, 5, 5, 6, 7 ] } },
                TP => { advance_cost => { W => 2, C => 3 },
                        income => { C => [ 0, 2, 4, 6, 8 ],
                                    PW => [ 0, 1, 2, 4, 6 ] } },
                TE => { advance_cost => { W => 2, C => 5 },
                        income => { P => [ 0, 1, 1, 2 ],
                                    PW => [ 0, 0, 5, 0 ] } },
                SH => { advance_cost => { W => 4, C => 6 },
                        advance_gain => [ { BRIDGE => 2 } ],
                        subactions => {
                            bridge => 2,
                        },
                        income => { PW => [ 0, 2 ] } },
                SA => { advance_cost => { W => 4, C => 6 },
                        income => { P => [ 0, 1 ] } },
            }},
    },
);

Readonly our %final_scoring => (
    network => {
        description => "Largest connected network of buildings",
        points => [18, 12, 6],
        label => "network",
    },
    'connected-distance' => {
        description => "Largest distance between two buildings in one network of connected buildings",
        option => 'fire-and-ice-final-scoring',
        points => [18, 12, 6],
        label => 'distance',
    },
    'connected-sa-sh-distance' => {
        description => "Largest distance between a stronghold and sanctuary, which are in the same network of connected buildings",
        option => 'fire-and-ice-final-scoring',
        points => [18, 12, 6],
        label => 'sa-sh-distance',
    },
    'building-on-edge' => {
        description => "Largest number of buildings on the edge of the map and in the same network of connected buildings",
        option => 'fire-and-ice-final-scoring',
        points => [18, 12, 6],
        label => 'edge',
    },
    'connected-clusters' => {
        description => "Most separate clusters in one network of connected buildings. (Where a cluster is a group of directly connected buildings).",
        option => 'fire-and-ice-final-scoring',
        points => [18, 12, 6],
        label => 'clusters',
    },
    'cults' => {
        description => "Position on each cult",
        points => [ 8, 4, 2 ]
    }
);

1;

