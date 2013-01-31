package terra_mystica;

use strict;

use map;

use vars qw(@cults);
our @cults = qw(FIRE WATER EARTH AIR);

for my $cult (@cults) {
    $map{"${cult}1"} = { gain => { $cult => 3 } };
    $map{"${cult}$_"} = { gain => { $cult => 2 } } for 2..4;
}

1;

