package terra_mystica;

use strict;

use map;
use Util::NaturalCmp;

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
    return 0 if $map{$where}{town};

    # Must not be empty.
    return 0 if !$map{$where}{building};

    # Must be controlled by faction. (Necessary e.g. when a bridge is
    # added).
    return 0 if $map{$where}{color} ne $faction->{color};

    my @adjacent = keys %{$map{$where}{adjacent}};

    # We might need to merge the building to existing town instead of
    # forming a new one.
    for my $adjacent (adjacent_own_buildings $faction, $where) {
        if ($map{$adjacent}{town}) {
            add_to_town $faction, $where, $map{$adjacent}{town};
        }
    }

    # ... and if that happened, we need to bail out at this point.
    return 0 if $map{$where}{town};

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
        my $type = $map{$loc}{building};
        my $str = $faction->{building_strength}{$type} // $building_strength{$type};
        $power += $str;
        $count++;
        # Sanctuary counts as two buildings.
        $count++ if $map{$loc}{building} eq 'SA';

        for my $adjacent (adjacent_own_buildings $faction, $loc) {
            $handle->($adjacent);
        }
    };
    $handle->($where);
    $handle = undef;

    my @reachable = keys %reachable;
    my $town_tile_count = grep { /^TW/ and $game{pool}{$_} > 0 } keys %{$game{pool}};
    if ($power >= $faction->{TOWN_SIZE} and $count >= 4 and
        $town_tile_count) {
        # Use the same town id for all towns for now.
        $map{$_}{town} = $town_tile_count for @reachable;
        adjust_resource($faction, "GAIN_TW", 1);
        return 1;
    }

    return 0;
}

sub check_mermaid_river_connection_town {
    my ($faction, $river) = @_;

    # Already a town bordering that river space.
    for my $adjacent (adjacent_own_buildings $faction, $river) {
        if ($map{$adjacent}{town}) {
            return 0;
        }
    }    

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
        if ($map{$loc}{building}) {
            my $type = $map{$loc}{building};
            my $str = $faction->{building_strength}{$type} // $building_strength{$type};
            $power += $str;
            $count++;
            # Sanctuary counts as two buildings.
            $count++ if $type eq 'SA';
        }

        for my $adjacent (adjacent_own_buildings $faction, $loc) {
            $handle->($adjacent);
        }
    };
    $handle->($river);
    $handle = undef;

    if ($power >= $faction->{TOWN_SIZE} and $count >= 4 and
        grep { /^TW/ and $game{pool}{$_} > 0 } keys %{$game{pool}}) {
        return 1;
    }

    return 0;
}

sub update_mermaid_town_connections {
    my $mermaids = $game{acting}->factions()->{mermaids};
    return if !$mermaids;

    my @valid_spaces = ();

    for my $river (keys %map) {
        next if $river !~ /^r/;
        if (check_mermaid_river_connection_town $mermaids, $river) {
            push @valid_spaces, $river;
            $map{$river}{possible_town} = 1;
        }
    }

    $mermaids->{possible_towns} = [
        sort { natural_cmp $a, $b } @valid_spaces
    ];
}

1;
