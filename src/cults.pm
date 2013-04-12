package terra_mystica;

use strict;

use vars qw(@cults %cults);
our @cults = qw(FIRE WATER EARTH AIR);
our %cults = ();

sub setup_cults {
    for my $cult (@cults) {
        $cults{"${cult}1"} = { gain => { $cult => 3 } };
        $cults{"${cult}$_"} = { gain => { $cult => 2 } } for 2..4;
    }
}

1;

