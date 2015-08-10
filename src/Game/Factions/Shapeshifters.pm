package Game::Factions::Shapeshifters;

use strict;
use Readonly;

Readonly our $shapeshifters_v4 => {
    C => 15, W => 3, P1 => 4, P2 => 4,
    FIRE => 1, WATER => 1,
    color => 'variable',
    board => 'variable',
    display => "Shapeshifters (playtest v4)",
    faction_board_id => undef,
    ALLOW_SHAPESHIFT => 10000,
    PICK_COLOR => 1,
    pick_color_field => 'color',
    leech_effect => {
        taken => {
            GAIN_P3_FOR_VP => 1,
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
                advance_gain => [ { ACTH3 => 1, ACTH4 => 1 } ],
                income => { PW => [ 0, 4 ] } },
        SA => { advance_cost => { W => 4, C => 6 },
                income => { P => [ 0, 1 ] } },
    }
};

Readonly our $shapeshifters_v3 => {
    C => 15, W => 3, P1 => 4, P2 => 4,
    FIRE => 1, WATER => 1,
    ALLOW_SHAPESHIFT => 0,
    color => 'variable',
    board => 'variable',
    display => "Shapeshifters (playtest v3)",
    faction_board_id => undef,
    PICK_COLOR => 1,
    pick_color_field => 'color',
    leech_effect => {
        taken => {
            GAIN_P3_FOR_VP => 1,
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
                advance_gain => [ { ACTH1 => 1, ACTH2 => 1, ALLOW_SHAPESHIFT => 'OPPONENT_COUNT' } ],
                income => { PW => [ 0, 4 ] } },
        SA => { advance_cost => { W => 4, C => 6 },
                income => { P => [ 0, 1 ] } },
    }
};

Readonly our $shapeshifters_v2 => {
    C => 15, W => 3, P1 => 4, P2 => 4,
    FIRE => 1, WATER => 1,
    ALLOW_SHAPESHIFT => 0,
    color => 'variable',
    board => 'variable',
    display => "Shapeshifters (playtest v2)",
    faction_board_id => undef,
    PICK_COLOR => 1,
    pick_color_field => 'color',
    leech_effect => {
        taken => {
            GAIN_P3_FOR_VP => 1,
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
                advance_gain => [ { ACTH1 => 1, ACTH2 => 1, ALLOW_SHAPESHIFT => 'PLAYER_COUNT' } ],
                income => { PW => [ 0, 4 ] } },
        SA => { advance_cost => { W => 4, C => 6 },
                income => { P => [ 0, 1 ] } },
    }
};

Readonly our $shapeshifters => {
    C => 15, W => 3, P1 => 4, P2 => 4,
    FIRE => 1, WATER => 1,
    ALLOW_SHAPESHIFT => 100,
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
    }
};

