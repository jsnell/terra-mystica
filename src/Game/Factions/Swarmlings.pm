package Game::Factions::Swarmlings;

use strict;
use Readonly;

Readonly our $swarmlings => {
    C => 20, W => 8, P1 => 3, P2 => 9,
    FIRE => 1, EARTH => 1,
    WATER => 1, AIR => 1, color => 'blue',
    display => "Swarmlings",
    faction_board_id => 5,
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
        advance_cost => { W => 2, C => 5, P => 1 },
        advance_gain => [ { VP => 6 },
                          { VP => 6 } ],
    },
    special => {
        mode => 'gain',
        map(("TW$_", { W => 3 }), 1..8),
    },
	action => {
		ACTP => { cost => { W => 2, C => 2 }, gain => { SP => 1 } },
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
		SY => { advance_cost => { W => 5, C => 8 },
				advance_gain => [ { ACTP => 1, SP => 1, GAIN_SHIP => 1 } ],
                income => { SP => 1 } },
    }
};
