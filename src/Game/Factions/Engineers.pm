package Game::Factions::Engineers;

use strict;
use Readonly;

Readonly our $engineers => {
    C => 10, W => 2, P1 => 3, P2 => 9,
	color => 'gray',
    display => "Engineers",
    faction_board_id => 8,
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
		SY => { advance_cost => { },
				advance_gain => [ { } ],
                income => { } },
    }
};
