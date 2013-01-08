use vars qw(%map);
use strict;

our %map = ();

my @map = qw(brown gray green blue yellow red brown black red green blue red black E
             yellow x x brown black x x yellow black x x yellow E
             x x black x gray x green x green x gray x x E
             green blue yellow x x red blue x red x red brown E
             black brown red blue black brown gray yellow x x green black blue E
             gray green x x yellow green x x x brown gray brown E
             x x x gray x red x green x yellow black blue yellow E
             yellow blue brown x x x blue black x gray brown gray E
             red black gray blue red green yellow brown gray x blue green red E); 

{
    my $ri = 0;
    for my $row ('A'..'I') {
        my $col = 1;
        for my $ci (0..13) {
            my $color = shift @map;
            last if $color eq 'E';
            if ($color ne 'x') {
                $map{"$row$col"}{color} = $color;
                $map{"$row$col"}{row} = $ri;
                $map{"$row$col"}{col} = $ci;
                $col++;
            }
        }
        $ri++;
    }
}

1;
