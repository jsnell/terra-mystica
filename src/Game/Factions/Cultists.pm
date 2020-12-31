package Game::Factions::Cultists;

use strict;
use Readonly;

Readonly our $cultists => {
    C => 15, W => 3, P1 => 5, P2 => 7,
    EARTH => 1, FIRE => 1, color => 'brown',
    display => "Cultists",
    faction_board_id => 10,
    ship => { 
        level => 0, max_level => 3,
        advance_cost => { C => 4, P => 1 },
        advance_gain => [ { VP => 2 },
                          { VP => 3 },
                          { VP => 4 } ],
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
                          { VP => 6 } ],
    },
	action => {
		ACTP => { cost => { W => 1, C => 2 }, gain => { SP => 1 } },
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
		SY => { advance_cost => { W => 4, C => 6 },
				advance_gain => [ { ACTP => 1, GAIN_SHIP => 1 } ],
                income => { SP => 1 } },
    }
};
