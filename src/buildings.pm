package terra_mystica;

use strict;
use Readonly;

use Game::Constants;

sub alias_building {
    my $type = shift;

    return $building_aliases{$type} // $type;
}

1;
