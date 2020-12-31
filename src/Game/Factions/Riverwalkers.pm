package Game::Factions::Riverwalkers;

use strict;
use Readonly;

Readonly our $riverwalkers_v5 => {
    C => 15, W => 3, P1 => 10, P2 => 2,
    FIRE => 1, AIR => 1, MAX_P => 1,
    color => 'variable',
    board => 'variable',
    display => "Riverwalkers",
    full_name => 'riverwalkers_v5',
    faction_board_id => undef,
    PICK_COLOR => 1,
    pick_color_field => 'color',
    adjacency => {
        direct => 0,
    },
    ship => {
        level => 1, max_level => 1,
    },
    locked_terrain => {
        'gain-priest' => { '' => { gain => { P => 1 }, permanent => 1 } },
        map { 
            ($_, {
                home => { gain => { MAX_P => 1 }, cost => { C => 2 } },
                not_home => { gain => { MAX_P => 1 }, cost => { C => 1 } },
             })
        } qw(yellow brown black blue green gray red),
    },
    # Immediately lose any spades that are gained
    special => {
        SPADE => { },
        P => { UNLOCK_TERRAIN => 1 },
        mode => 'replace',
    }, 
    # Can't take a spade-producing special action
    action => {
        BON1 => { forbid => 1 },
        ACT5 => { forbid => 1 },
        ACT6 => { forbid => 1 },
		ACTP => { cost => { W => 1, C => 2 }, gain => { SP => 1 } },
    },
    # no explicit dig action
    buildings => {
        D => { advance_cost => { W => 1, C => 2 },
               income => { W => [ 1, 2, 3, 3, 4, 5, 5, 6, 7 ] } },
        TP => { advance_cost => { W => 2, C => 3 },
                income => { C => [ 0, 2, 4, 6, 8 ],
                            PW => [ 0, 1, 2, 4, 6 ] } },
        TE => { advance_cost => { W => 2, C => 5 },
                income => { P => [ 0, 1, 1, 2 ],
                            PW => [ 0, 0, 5, 5 ] } },
        SH => { advance_cost => { W => 4, C => 6 },
                advance_gain => [ { BRIDGE => 2 } ],
                subactions => {
                    bridge => 2,
                },
                income => { PW => [ 0, 2 ] } },
        SA => { advance_cost => { W => 4, C => 6 },
                income => { P => [ 0, 1 ] } },
		SY => { advance_cost => { W => 4, C => 6 },
				advance_gain => [ { ACTP => 1, SP => 1 } ],
                income => { SP => 1 } },
    }
};

Readonly our $riverwalkers_v4 => {
    C => 15, W => 3, P1 => 10, P2 => 2,
    FIRE => 1, AIR => 1, MAX_P => 1,
    color => 'variable',
    board => 'variable',
    display => "Riverwalkers (playtest v4)",
    full_name => 'riverwalkers_v4',
    faction_board_id => undef,
    PICK_COLOR => 1,
    pick_color_field => 'color',
    adjacency => {
        direct => 0,
    },
    ship => {
        level => 1, max_level => 1,
    },
    locked_terrain => {
        'gain-priest' => { '' => { gain => { P => 1 }, permanent => 1 } },
        map { 
            ($_, {
                home => { gain => { MAX_P => 1 }, cost => { C => 3 } },
                not_home => { gain => { MAX_P => 1 }, cost => { C => 2 } },
             })
        } qw(yellow brown black blue green gray red),
    },
    # Immediately lose any spades that are gained
    special => {
        SPADE => { },
        P => { UNLOCK_TERRAIN => 1 },
        mode => 'replace',
    }, 
    # Can't take a spade-producing special action
    action => {
        BON1 => { forbid => 1 },
        ACT5 => { forbid => 1 },
        ACT6 => { forbid => 1 },
    },
    # no explicit dig action
    buildings => {
        D => { advance_cost => { W => 1, C => 2 },
               income => { W => [ 1, 2, 3, 3, 4, 5, 5, 6, 7 ] } },
        TP => { advance_cost => { W => 2, C => 3 },
                income => { C => [ 0, 2, 4, 6, 8 ],
                            PW => [ 0, 1, 2, 4, 6 ] } },
        TE => { advance_cost => { W => 2, C => 5 },
                income => { P => [ 0, 1, 1, 2 ],
                            PW => [ 0, 0, 5, 5 ] } },
        SH => { advance_cost => { W => 4, C => 6 },
                advance_gain => [ { BRIDGE => 2 } ],
                subactions => {
                    bridge => 2,
                },
                income => { PW => [ 0, 2 ] } },
        SA => { advance_cost => { W => 4, C => 6 },
                income => { P => [ 0, 1 ] } },
    }
};

Readonly our $riverwalkers => {
    C => 15, W => 3, P1 => 10, P2 => 2,
    FIRE => 1, AIR => 1, MAX_P => 1,
    color => 'variable',
    board => 'variable',
    display => "Riverwalkers (orig)",
    faction_board_id => undef,
    PICK_COLOR => 1,
    pick_color_field => 'color',
    adjacency => {
        direct => 0,
    },
    ship => {
        level => 1, max_level => 1,
    },
    locked_terrain => {
        'gain-priest' => { '' => { gain => { P => 1 }, permanent => 1 } },
        map { 
            ($_, {
                home => { gain => { MAX_P => 1 } },
                not_home => { gain => { MAX_P => 1 } },
             })
        } qw(yellow brown black blue green gray red),
    },
    # Immediately lose any spades that are gained
    special => {
        SPADE => { },
        P => { UNLOCK_TERRAIN => 1 },
        mode => 'replace',
    }, 
    # Can't take a spade-producing special action
    action => {
        BON1 => { forbid => 1 },
        ACT5 => { forbid => 1 },
        ACT6 => { forbid => 1 },
    },
    # no explicit dig action
    buildings => {
        D => { advance_cost => { W => 1, C => 2 },
               income => { W => [ 1, 2, 3, 3, 4, 5, 5, 6, 7 ] } },
        TP => { advance_cost => { W => 2, C => 3 },
                income => { C => [ 0, 2, 4, 6, 8 ],
                            PW => [ 0, 1, 2, 4, 6 ] } },
        TE => { advance_cost => { W => 2, C => 5 },
                income => { P => [ 0, 1, 1, 2 ],
                            PW => [ 0, 0, 5, 5 ] } },
        SH => { advance_cost => { W => 4, C => 6 },
                advance_gain => [ { BRIDGE => 2 } ],
                subactions => {
                    bridge => 2,
                },
                income => { PW => [ 0, 2 ] } },
        SA => { advance_cost => { W => 4, C => 6 },
                income => { P => [ 0, 1 ] } },
    }
};
