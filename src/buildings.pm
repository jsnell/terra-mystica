package terra_mystica;

use strict;
use Readonly;

use vars qw(%building_strength);
Readonly our %building_strength => (
    D => 1,
    TP => 2,
    TE => 2,
    SH => 3,
    SA => 3,
);

Readonly my %building_aliases => (
    DWELLING => 'D',
    'TRADING POST' => 'TP',
    TEMPLE => 'TE',
    STRONGHOLD => 'SH',
    SANCTUARY => 'SA',
);

sub alias_building {
    my $type = shift;

    return $building_aliases{$type} // $type;
}

1;
