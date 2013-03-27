package terra_mystica;

use strict;

use map;
use vars qw(%pool);

# Add a hex with a building owned by faction to the town denoted by tid.
# Also add all transitively directly adjacent buildings to the town.
sub add_to_town {
    my ($faction, $where, $tid) = @_;

    $map{$where}{town} = $tid;

    for my $adjacent (adjacent_own_buildings $faction, $where) {
        if (!$map{$adjacent}{town}) {
            add_to_town($faction, $adjacent, $tid);
        }
    }
}

# Given a faction and a hex, check whether something that happened in
# that hex now allows for a formation of a new town.
sub detect_towns_from {
    my ($faction, $where) = @_;

    # Must not already be part of a town.
    return if $map{$where}{town};

    # Must not be empty.
    return if !$map{$where}{building};

    # Must be controlled by faction. (Necessary e.g. when a bridge is
    # added).
    return if $map{$where}{color} ne $faction->{color};

    my @adjacent = keys %{$map{$where}{adjacent}};

    # We might need to merge the building to existing town instead of
    # forming a new one.
    for my $adjacent (adjacent_own_buildings $faction, $where) {
        if ($map{$adjacent}{town}) {
            add_to_town $faction, $where, $map{$adjacent}{town};
        }
    }

    # ... and if that happened, we need to bail out at this point.
    return if $map{$where}{town};

    my %reachable = ();
    my $power = 0;
    my $count = 0;

    # Count the number and power of the buildings reachable from this
    # hex.
    my $handle;
    $handle = sub {
        my ($loc) = @_;
        return if exists $reachable{$loc};

        $reachable{$loc} = 1;
        $power += $building_strength{$map{$loc}{building}};
        $count++;
        # Sanctuary counts as two buildings.
        $count++ if $map{$loc}{building} eq 'SA';

        for my $adjacent (adjacent_own_buildings $faction, $loc) {
            $handle->($adjacent);
        }
    };
    $handle->($where);

    if ($power >= $faction->{TOWN_SIZE} and $count >= 4 and
        grep { /^TW/ and $pool{$_} > 0 } keys %pool) {
        # Use the same town id for all towns for now.
        $map{$_}{town} = 1 for keys %reachable;
        adjust_resource($faction, "GAIN_TW", 1);
    }
}

1;
