use strict;
use vars qw(%actions %tiles);
use Readonly;

Readonly our %actions => (
    ACT1 => { cost => { PW => 3 }, gain => { BRIDGE => 1 },
              subaction => { 'bridge' => 1 }},
    ACT2 => { cost => { PW => 3 }, gain => { P => 1 } },
    ACT3 => { cost => { PW => 4 }, gain => { W => 2 } },
    ACT4 => { cost => { PW => 4 }, gain => { C => 7 } },
    ACT5 => { cost => { PW => 4 }, gain => { SPADE => 1 },
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    ACT6 => { cost => { PW => 6 }, gain => { SPADE => 2 },
              subaction => { dig => 1, 'transform' => 2, 'build' => 1} },
    ACTA => { cost => {}, gain => { CULT => 2} },
    ACTG => { cost => {}, gain => { SPADE => 2},
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    ACTS => { cost => {}, gain => { FREE_TP => 1 },
              subaction => { 'upgrade' => 1 }},
    ACTN => { cost => {}, gain => { FREE_TF => 1 },
              subaction => { dig => 1, 'transform' => 1, 'build' => 1 } },
    ACTW => { cost => {}, gain => { FREE_D => 1, TELEPORT_NO_TF => 1 },
              subaction => { 'build' => 1 } },
    ACTC => { cost => {}, gain => { GAIN_ACTION => 2 } },
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
                cult => 'EARTH',
                req => 1, 
                income => { C => 1 } },
    SCORE2 => { vp => { map(("TW$_", 5), 1..8) },
                vp_display => 'TOWN >> 5',
                cult => 'EARTH',
                req => 4, 
                income => { SPADE => 1 } },
    SCORE3 => { vp => { D => 2 },
                vp_display => 'D >> 2',
                cult => 'WATER',
                req => 4, 
                income => { P => 1 } },    
    SCORE4 => { vp => { SA => 5, SH => 5 },
                vp_display => 'SA/SH >> 5',
                cult => 'FIRE',
                req => 2,
                income => { W => 1 } },    
    SCORE5 => { vp => { D => 2 },
                vp_display => 'D >> 2',
                cult => 'FIRE',
                req => 4, 
                income => { PW => 4 } },    
    SCORE6 => { vp => { TP => 3 },
                vp_display => 'TP >> 3',
                cult => 'WATER',
                req => 4, 
                income => { SPADE => 1 } },    
    SCORE7 => { vp => { SA => 5, SH => 5 },
                vp_display => 'SA/SH >> 5',
                cult => 'AIR',
                req => 2,
                income => { W => 1 } },    
    SCORE8 => { vp => { TP => 3 },
                vp_display => 'TP >> 3',
                cult => 'AIR',
                req => 4, 
                income => { SPADE => 1 } },    

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

1;
