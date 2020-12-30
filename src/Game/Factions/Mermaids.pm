package Game::Factions::Mermaids;

use strict;
use Readonly;

Readonly our $mermaids => { 
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
                          { VP => 5 } ],
    },
    dig => {
        level => 0, max_level => 2,
        cost => [ { W => 3 }, { W => 2 }, { W => 1 } ],
        advance_cost => { W => 2, C => 5, P => 1 },
        advance_gain => [ { VP => 6 },
                          { VP => 6 } ],
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
		SY => { advance_cost => { },
				advance_gain => [ { } ],
                income => { } },
    }
};

