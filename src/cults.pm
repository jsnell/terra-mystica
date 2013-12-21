package terra_mystica;

use strict;
use Readonly;

use vars qw(@cults);
Readonly our @cults => qw(FIRE WATER EARTH AIR);

sub setup_cults {
    my %cults = ();
    for my $cult (@cults) {
        $cults{"${cult}1"} = { gain => { $cult => 3 } };
        $cults{"${cult}$_"} = { gain => { $cult => 2 } } for 2..4;
    }

    \%cults;
}

1;

