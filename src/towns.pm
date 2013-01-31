package terra_mystica;

use strict;

use map;

sub add_to_town {
    my ($faction, $where, $tid) = @_;

    $map{$where}{town} = $tid;

    for my $adjacent (adjacent_own_buildings $faction, $where) {
        if (!$map{$adjacent}{town}) {
            add_to_town($faction, $adjacent, $tid);
        }
    }
}

sub detect_towns_from {
    my ($faction, $where) = @_;

    return if $map{$where}{town};
    return if !$map{$where}{building};
    return if $map{$where}{color} ne $faction->{color};

    my @adjacent = keys %{$map{$where}{adjacent}};

    # Merge building to existing town
    for my $adjacent (adjacent_own_buildings $faction, $where) {
        if ($map{$adjacent}{town}) {
            add_to_town $faction, $where, $map{$adjacent}{town};
        }
    }

    return if $map{$where}{town};

    my %reachable = ();
    my $power = 0;
    my $count = 0;

    my $handle;
    $handle = sub {
        my ($loc) = @_;
        return if exists $reachable{$loc};

        $reachable{$loc} = 1;
        $power += $building_strength{$map{$loc}{building}};
        $count++;
        $count++ if $map{$loc}{building} eq 'SA';

        for my $adjacent (adjacent_own_buildings $faction, $loc) {
            $handle->($adjacent);
        }
    };

    $handle->($where);

    if ($power >= $faction->{TOWN_SIZE} and $count >= 4) {
        $map{$_}{town} = 1 for keys %reachable;
        adjust_resource($faction, "GAIN_TW", 1);
    }
}

1;
