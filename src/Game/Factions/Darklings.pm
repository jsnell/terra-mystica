package Game::Factions::Darklings;

use strict;
use Readonly;

Readonly our $darklings => { 
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
                          { VP => 4 } ],
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
		SY => { advance_cost => { },
				advance_gain => [ { } ],
                income => { } },
    }
};
