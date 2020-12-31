package Game::Factions::Acolytes;

use strict;
use Readonly;

Readonly our $acolytes => {
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
		ACTP => { cost => { W => 1, C => 2 }, gain => { SP => 1 } },
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
		SY => { advance_cost => { W => 4, C => 6 },
				advance_gain => [ { ACTP => 1, SP => 1, GAIN_SHIP => 1 } ],
                income => { SP => 1 } },
    }};

Readonly our $acolytes_playtest_v1 => {
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
    }
};

Readonly our $acolytes_playtest_v2 => {
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
    }};

Readonly our $acolytes_playtest_v3 => {
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
    }
};
