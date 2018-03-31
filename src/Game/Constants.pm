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
               show_if => 'ALLOW_SHAPESHIFT',
               cost => { PW => 3, ALLOW_SHAPESHIFT => 1 },
               gain => { PICK_COLOR => 1, 
                         VP => 2 } },
    ACTH2 => { dont_block => 1,
               show_if => 'ALLOW_SHAPESHIFT',
               cost => { PW_TOKEN => 3, ALLOW_SHAPESHIFT => 1 },
               gain => { PICK_COLOR => 1, 
                         VP => 2 } },
    ACTH3 => { dont_block => 1,
               cost => { PW => 4 },
               gain => { PICK_COLOR => 1 } },
    ACTH4 => { dont_block => 1,
               cost => { PW_TOKEN => 4 },
               gain => { PICK_COLOR => 1 } },
    ACTH5 => { dont_block => 1,
               cost => { PW => 5 },
               gain => { PICK_COLOR => 1 } },
    ACTH6 => { dont_block => 1,
               cost => { PW_TOKEN => 5 },
               gain => { PICK_COLOR => 1 } },
    BON1 => { cost => {}, gain => { SPADE => 1 },
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    BON2 => { cost => {}, gain => { CULT => 1 } },
    FAV6 => { cost => {}, gain => { CULT => 1 } },
);
       
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
    SCORE9 => { vp => { TE => 4 },
                vp_display => 'TE >> 4',
                vp_mode => 'build',
                cult => 'CULT_P',
                req => 1,
                option => 'temple-scoring-tile',
                income => { C => 2 } },    

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

use Game::Factions::Acolytes;
use Game::Factions::Alchemists;
use Game::Factions::Auren;
use Game::Factions::Chaosmagicians;
use Game::Factions::Cultists;
use Game::Factions::Darklings;
use Game::Factions::Dragonlords;
use Game::Factions::Dwarves;
use Game::Factions::Engineers;
use Game::Factions::Fakirs;
use Game::Factions::Giants;
use Game::Factions::Halflings;
use Game::Factions::Icemaidens;
use Game::Factions::Mermaids;
use Game::Factions::Nomads;
use Game::Factions::Riverwalkers;
use Game::Factions::Shapeshifters;
use Game::Factions::Swarmlings;
use Game::Factions::Witches;
use Game::Factions::Yetis;

Readonly our %faction_setups => (
    alchemists => $Game::Factions::Alchemists::alchemists,
    auren => $Game::Factions::Auren::auren,
    chaosmagicians => $Game::Factions::Chaosmagicians::chaosmagicians,
    cultists => $Game::Factions::Cultists::cultists,
    darklings => $Game::Factions::Darklings::darklings,
    dwarves => $Game::Factions::Dwarves::dwarves,
    engineers => $Game::Factions::Engineers::engineers,
    fakirs => $Game::Factions::Fakirs::fakirs,
    giants => $Game::Factions::Giants::giants,
    halflings => $Game::Factions::Halflings::halflings,
    mermaids => $Game::Factions::Mermaids::mermaids,
    nomads => $Game::Factions::Nomads::nomads,
    swarmlings => $Game::Factions::Swarmlings::swarmlings,
    witches => $Game::Factions::Witches::witches,
);

Readonly our %faction_setups_extra => (
    playtest_v1_ice => {
        icemaidens => $Game::Factions::Icemaidens::icemaidens_playtest_v1,
        yetis => $Game::Factions::Yetis::yetis_playtest_v1,
    },
    final_ice => {
        icemaidens => $Game::Factions::Icemaidens::icemaidens,
        yetis => $Game::Factions::Yetis::yetis,
    },
    playtest_v1_volcano => {
        acolytes => $Game::Factions::Acolytes::acolytes_playtest_v1,
        dragonlords => $Game::Factions::Dragonlords::dragonlords_playtest_v1,
    },
    playtest_v2_volcano => {
        acolytes => $Game::Factions::Acolytes::acolytes_playtest_v2,
        dragonlords => $Game::Factions::Dragonlords::dragonlords_playtest_v2,
    },
    playtest_v3_volcano => {
        acolytes => $Game::Factions::Acolytes::acolytes_playtest_v3,
        dragonlords => $Game::Factions::Dragonlords::dragonlords_playtest_v3,
    },
    final_volcano => {
        acolytes => $Game::Factions::Acolytes::acolytes,
        dragonlords => $Game::Factions::Dragonlords::dragonlords,
    },

    final_variable => {
        riverwalkers => $Game::Factions::Riverwalkers::riverwalkers,
        shapeshifters => $Game::Factions::Shapeshifters::shapeshifters,
    },
    final_variable_v2 => {
        riverwalkers => $Game::Factions::Riverwalkers::riverwalkers,
        shapeshifters => $Game::Factions::Shapeshifters::shapeshifters_v2,
    },
    final_variable_v3 => {
        riverwalkers => $Game::Factions::Riverwalkers::riverwalkers,
        shapeshifters => $Game::Factions::Shapeshifters::shapeshifters_v3,
    },
    final_variable_v4 => {
        riverwalkers => $Game::Factions::Riverwalkers::riverwalkers_v4,
        shapeshifters => $Game::Factions::Shapeshifters::shapeshifters_v4,
    },
    final_variable_v5 => {
        riverwalkers => $Game::Factions::Riverwalkers::riverwalkers_v5,
        shapeshifters => $Game::Factions::Shapeshifters::shapeshifters_v5,
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

Readonly our %vp_setups => (
    original_2017 => {
        darklings => 15,
        cultists => 16,
        engineers => 16,
        chaosmagicians => 19,
        mermaids => 19,
        nomads => 19,
        witches => 19,
        dwarves => 20,
        halflings => 20,
        icemaidens => 20,
        riverwalkers => 21,
        shapeshifters => 22,
        swarmlings => 22,
        yetis => 22,
        acolytes => 23,
        dragonlords => 24,
        giants => 25,
        alchemists => 27,
        auren => 27,
        fakirs => 33,
    }
);

1;

