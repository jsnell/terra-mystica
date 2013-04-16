#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use Clone qw(clone);

use vars qw(%factions %factions_by_color @factions @setup_order @players);

my %setups = (
    alchemists => { C => 15, W => 3, P1 => 5, P2 => 7,
                    WATER => 1, FIRE => 1, color => 'black',
                    display => "Alchemists",
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
               display => "Auren",
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
                 display => "Witches",
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
                display => "Nomads",
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
                ship => { 
                    level => 0, max_level => 0,
                },
                teleport => {
                    level => 0, max_level => 1,
                    cost => [ { P => 1 }, { P => 1 } ],
                    gain => [ { VP => 4 }, { VP => 4 } ],
                    range => [ 1, 2 ],
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
                            advance_gain => [ { GAIN_TELEPORT => 1 } ],
                            income => { P => [ 0, 1 ] } },
                    SA => { advance_cost => { W => 4, C => 6 },
                            income => { P => [ 0, 1 ] } },
                }},
    engineers => { C => 10, W => 2, P1 => 3, P2 => 9, color => 'gray',
                   display => "Engineers",
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
                   exchange_rates => {
                       W => { BRIDGE => 2 }
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
    dwarves => { C => 15, W => 3, P1 => 5, P2 => 7,
                EARTH => 2, color => 'gray',
                display => "Dwarves",
                ship => { 
                    level => 0, max_level => 0,
                },
                teleport => {
                    level => 0, max_level => 1,
                    cost => [ { W => 2 }, { W => 1 } ],
                    gain => [ { VP => 4 }, { VP => 4 } ],
                    range => [ 1, 1 ],
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
                   special => {
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
                       SH => { advance_cost => { W => 4, C => 8 },
                               advance_gain => [ { VP => 7 } ],
                               income => { PW => [ 0, 2 ] } },
                       SA => { advance_cost => { W => 4, C => 8 },
                               income => { P => [ 0, 1 ] } },
               }},
);

sub setup {
    my ($faction_name, $player, $email) = @_;

    die "Unknown faction: $faction_name\n" if !$setups{$faction_name};

    my $faction = $factions{$faction_name} = clone($setups{$faction_name});
    my $player_record = {};
    if (@players) {
        $player_record = $players[@factions];
        if ($player ne $player_record->{name}) {
            die "Expected ".($player_record->{name})." to pick a faction";
        }
        $email ||= $player_record->{email};
    }

    if ($player) {
        $faction->{display} .= " ($player)";
        $faction->{player} = "$player";
    }

    $faction->{name} = $faction_name;
    $faction->{start_player} = 1 if !@factions;
    $faction->{email} = $email;

    $faction->{allowed_actions} = 0;

    if ($factions_by_color{$faction->{color}}) {
        my $other_name = $factions_by_color{$faction->{color}}->{name};
        die "Can't add $faction_name, $other_name already in use\n";
    }
    $factions_by_color{$faction->{color}} = $faction;

    $faction->{P} ||= 0;
    $faction->{P1} ||= 0;
    $faction->{P2} ||= 0;
    $faction->{P3} ||= 0;

    $faction->{VP} = $faction->{vp_source}{initial} = 20;
    $faction->{KEY} = 0;

    $faction->{MAX_P} = 7;

    my @cults = qw(EARTH FIRE WATER AIR);
    for (@cults) {
        $faction->{$_} ||= 0;
        $faction->{"MAX_$_"} = 10;
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

    $faction->{SPADE} = 0;
    $faction->{TOWN_SIZE} = 7;

    push @factions, $faction_name;

    @setup_order = @factions;
    push @setup_order, reverse @factions;
    push @setup_order, 'nomads' if $factions{nomads};

    if ($factions{chaosmagicians}) {
        @setup_order = grep { $_ ne 'chaosmagicians' } @setup_order;
        push @setup_order, 'chaosmagicians';
    }
    push @setup_order, reverse @factions;

    @action_required = ({ type => 'dwelling', faction => $setup_order[0] });
}

sub factions_in_order_from {
    my $faction = shift;
    die "Internal error" if !$factions{$faction};

    my @f = @factions;
    while ($f[-1] ne $faction) {
        push @f, shift @f;
    }
    
    @f;
}

sub factions_in_turn_order {
    my ($start_player) = grep { $_->{start_player} } values %factions;
    my @order = factions_in_order_from $start_player->{name};
    my $a = pop @order;
    unshift @order, $a;

    return @order;
}

1;
