package Game::Factions::Dwarves;

use strict;
use Readonly;

Readonly our $dwarves => {
    C => 15, W => 3, P1 => 5, P2 => 7,
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
        advance_gain => [ { VP => 6 }, { VP => 6 } ],
    },
	action => {
		ACTM => { cost => { W => 1, C => 2 }, gain => { SP => 1 } },
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
		SE => { advance_cost => { W => 4, C => 6 },
				advance_gain => [ { SP => 1, ACTM => 1, GAIN_SHIP => 1 } ],
                income => { SP => 1 } },
    }
};

