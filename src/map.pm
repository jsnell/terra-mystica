#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use 5.010;

use Carp;
use Clone qw(clone);

use vars qw(%game);
use vars qw(%map);

# Initialize %map, with the correct coordinates, from the above raw data.
sub setup_base_map {
    my ($base_map, $reverse_map) = @_;
    my @row_labels = 'A'..'Z';
    my $row_count = grep { $_ eq 'E' } @{$base_map};

    my $i = 0;
    my $ri = 0;
    my $river = 0;
    for my $row (@row_labels[0..$row_count - 1]) {
        my $col = 1;
        for my $ci (0..13) {
            my $color = $base_map->[$i++];
            last if $color eq 'E';
            if ($color ne 'x') {
                my $key = "$row$col";
                $map{$key}{color} = $color;
                $map{$key}{row} = $ri;
                $map{$key}{col} = $ci;
                $reverse_map->{$ri}{$ci} = $key;
                $col++;
            } else {
                my $key = "r$river";
                $map{"$key"}{color} = 'white';
                $map{"$key"}{row} = $ri;
                $map{"$key"}{col} = $ci;
                $reverse_map->{$ri}{$ci} = "$key";
                $river++;
            }
        }
        $ri++;
    }

    my @rows = sort { $a <=> $b } keys %{$reverse_map};
    for my $row (@rows) {
        my @cols = sort { $a <=> $b } keys %{$reverse_map->{$row}};
        for my $col (@cols) {
            my $loc = $reverse_map->{$row}{$col};
            if ($col == $cols[0] or
                $col == $cols[-1] or
                $row == $rows[0] or
                $row == $rows[-1]) {
                $map{$loc}{edge} = 1;
            }
        }
    }
    
}

# Set up the a list of directly adjacent hexes. Store it under the
# 'adjacent' hash key.
sub setup_direct_adjacencies {
    my ($reverse_map) = @_;

    sub record_adjacent {
        my ($this, $other) = @_;
        if ($other) {
            $map{$this}{adjacent}{$other}++;
        }
    }

    for my $coord (keys %map) {
        my $row = $map{$coord}{row};
        my $col = $map{$coord}{col};

        # Same row
        record_adjacent $coord, $reverse_map->{$row}{$col+1};
        record_adjacent $coord, $reverse_map->{$row}{$col-1};

        # Adjacent rows. Need to offset the column by one for every other
        # row.
        if ($row % 2 == 0) {
            $col--;
        }

        record_adjacent $coord, $reverse_map->{$row - 1}{$col};
        record_adjacent $coord, $reverse_map->{$row - 1}{$col + 1};
        record_adjacent $coord, $reverse_map->{$row + 1}{$col};
        record_adjacent $coord, $reverse_map->{$row + 1}{$col + 1};
    }
}

# Distance between two hexes
sub hex_distance {
    my ($a, $b) = @_;
    
    if ($a eq $b) {
        return 0;
    }

    my $rdelta = abs $map{$a}{row} - $map{$b}{row};
    my $ac = $map{$a}{col} * 2 + $map{$a}{row} % 2;
    my $bc = $map{$b}{col} * 2 + $map{$b}{row} % 2;
    my $cdelta = abs $ac - $bc;

    $cdelta = abs $cdelta;
    $rdelta = abs $rdelta;

    if ($cdelta < $rdelta) {
        return $rdelta;
    }

    my $dist = 0;
    while ($rdelta > 1) {
        $rdelta -= 2;
        $cdelta -= 2;
        $dist += 2;
    }
    if ($rdelta) {
        $cdelta--;
        $dist++;
    }
    $dist += $cdelta / 2;

    return $dist;
}

# For each hex, set up a hash table 'range' > other-hex > mode, stating
# the distance from that hex to other-hex, when traveling via mode.
# 1 for river, 0 for like the crow flies.
sub setup_hex_ranges {
    my ($reverse_map, $from, $river_only) = @_;
    my %aux = ();
    my $max = ($river_only ? 6 : 4);

    return if $from =~ /^r/;

    $aux{$from} = -1;
    for my $range (0..$max) {
        for my $hex (keys %aux) {
            next if $aux{$hex} != $range - 1;
            next if $river_only and $range != 0 and $hex !~ /^r/;
            for my $adj (keys %{$map{$hex}{adjacent}}) {
                next if $river_only and $range == 0 and $adj !~ /^r/;
                if (!exists $aux{$adj}) { 
                    $aux{$adj} = $range;
                }
            }
        }
    }

    $map{$from}{range}{$river_only} = { %aux };
}

sub setup_ranges {
    my ($reverse_map) = @_;
    setup_hex_ranges $reverse_map, $_, 0 for keys %map;
    setup_hex_ranges $reverse_map, $_, 1 for keys %map;
}

sub setup_valid_bridges {
    my ($reverse_map) = @_;
    sub record_bridgable {
        my ($this, $other) = @_;
        if ($other and
            $other !~ /^r/ and
            exists $map{$this}{range}{1}{$other} and
            $map{$this}{range}{1}{$other} == 1) {
            $map{$this}{bridgable}{$other}++;
            $map{$other}{bridgable}{$this}++;
        }
    }

    for my $coord (keys %map) {
        my $row = $map{$coord}{row};
        my $col = $map{$coord}{col};
        my $offset_col = $col - !($row % 2);

        next if $coord =~ /^r/;

        # Same column, 2 rows off
        my $sw = ($reverse_map->{$row+1}{$offset_col} // '');
        my $se = ($reverse_map->{$row+1}{$offset_col+1} // '');
        if (($sw =~ /^r/ and $se =~ /^r/) or
            ($sw =~ /^r/ and !$se) or
            ($se =~ /^r/ and !$sw)) {
            record_bridgable $coord, $reverse_map->{$row+2}{$col};
        }

        # Adjacent row
        if (($reverse_map->{$row}{$col-1} // '') =~ /^r/ and
            ($reverse_map->{$row+1}{$offset_col} // '') =~ /^r/) {
            record_bridgable $coord, $reverse_map->{$row+1}{$offset_col-1};
        }
        if (($reverse_map->{$row}{$col+1} // '') =~ /^r/ and
            ($reverse_map->{$row+1}{$offset_col+1} // '') =~ /^r/) {
            record_bridgable $coord, $reverse_map->{$row+1}{$offset_col+2};
        }
    }    
}

# Check whether a faction can reach a given hex (directly, by ship, or
# by teleporting).
#
# If the faction needs to teleport, also pay the teleport cost here.
sub check_reachable {
    my ($faction, $where) = @_;

    if ($game{round} == 0) {
        return ({}, {}) 
    }

    my $range = $faction->{ship}{level};
    if ($faction->{ship}{max_level}) {
        if ($faction->{BON4} and
            # Bon4 doesn't apply in phase III
            !$faction->{passed}) {
            # XXX hack.
            $range++ 
        }
    }

    # Direct adjancies first (can't use tunneling / carpet flight bonus
    # if it isn't needed).
    if (!exists $faction->{adjacency} or
        $faction->{adjacency}{direct}) {
        for my $loc (@{$faction->{locations}}) {
            if ($map{$where}{adjacent}{$loc}) {
                return ({}, {});
            }
        }
    }

    # Ships
    if ($range) {
        for my $loc (@{$faction->{locations}}) {
            if (exists $map{$where}{range}{1}{$loc} and 
                $map{$where}{range}{1}{$loc} <= $range) {
                return ({}, {});
            }
        }
    }

    if ($faction->{TELEPORT_TO}) {
        if ($faction->{TELEPORT_TO} eq $where) {
            return ({}, {});
        } else {
            die "Can't use tunnel / carpet flight multiple times in one turn\n"
        }
    }

    if ($faction->{teleport} and !$faction->{passed}) {
        my $t = $faction->{teleport};
        my $level = $t->{level};
        my $type = $t->{type};
        my $range = $faction->{"${type}_range"};

        # XXX: shouldn't do payment here.
        for my $loc (@{$faction->{locations}}) {
            if (exists $map{$where}{range}{0}{$loc} and 
                $map{$where}{range}{0}{$loc} <= $range) {
                my $cost = clone $t->{cost}[$level];
                my $gain = clone $t->{gain}[$level];
                return ($cost || {}, $gain || {}, $faction->{teleport}{type});
            }
        }
    }

    die "$faction->{name} can't reach $where\n";
}

# Given a faction and a hex, return a list of all directly adjacent hexes
# that contain a building of that faction.
sub adjacent_own_buildings {
    my ($faction, $where) = @_;

    my @adjacent = keys %{$map{$where}{adjacent}};
    if ($faction->{name} eq 'mermaids' and exists $map{$where}{skip}) {
        push @adjacent, keys %{$map{$where}{skip}};
    }

    return grep {
        $map{$_}{building} and ($map{$_}{color} eq $faction->{color});
    } @adjacent;
}

sub find_building_cliques {
    my ($faction, $allow_indirect) = @_;

    my ($range, $ship);
    my %clique = ();

    # Dropped before faction selection
    return if !$faction->{locations};

    my @locations = @{$faction->{locations}};

    if ($faction->{teleport}) {
        my $t = $faction->{teleport};
        my $type = $t->{type};
        $range = $faction->{"${type}_range"};
        $ship = 0;
    } else {
        $range = $faction->{ship}{level};        
        $ship = 1;
    }

    # A depth-first search that marks all buildings that are
    # transitively directly adjacent to a given hex. Each building
    # will be assigned to the clique that matches the original
    # building from which the depth-first search started. A building
    # already in a clique won't change to another one.
    my $handle;
    $handle = sub {
        my ($loc, $id) = @_;
        return if exists $clique{$loc};

        $clique{$loc} = $id;

        for my $to (@locations) {
            next if $loc eq $to;
            if (exists $map{$loc}{adjacent}{$to} or
                ($faction->{name} eq 'mermaids' and
                 exists $map{$loc}{skip} and
                 exists $map{$loc}{skip}{$to}) or
                ($allow_indirect and
                 exists $map{$loc}{range}{$ship}{$to} and
                 $map{$loc}{range}{$ship}{$to} <= $range)) {
                $handle->($to, $id);
            };
        }
    };

    # Trigger the search for each building.
    my $n = 1;
    $handle->($_, $n++) for @locations;
    # Break the reference cycle.
    $handle = undef;

    %clique;
}

# Given a faction, compute the largest contiguous blob of buildings
# (taking into account river travel / teleporting).
sub compute_network_size {
    my $faction = shift;

    my %clique = find_building_cliques $faction, 1;
    my %clusters = find_building_cliques $faction, 0;
    
    {
        # Find the clique with the most members.
        my %clique_sizes = ();
        $clique_sizes{$_}++ for values %clique;
        # And that's the size of the network.
        $faction->{network} = max values %clique_sizes;
    }

    if ($game{final_scoring}{'connected-distance'}) {
        my $distance = 0;
        for my $a (keys %clique) {
            for my $b (keys %clique) {
                next if $clique{$a} != $clique{$b};
                my $new_dist = hex_distance $a, $b;
                $distance = max $distance, $new_dist;
            }
        }
        # And that's the size of the network.
        $faction->{'connected-distance'} = $distance;
    }

    if ($game{final_scoring}{'connected-sa-sh-distance'}) {
        my $distance = 0;
        for my $a (keys %clique) {
            for my $b (keys %clique) {
                next if $clique{$a} != $clique{$b};
                next if ($map{$a}{building} ne 'SA' or
                         $map{$b}{building} ne 'SH');
                my $new_dist = hex_distance $a, $b;
                $distance = max $distance, $new_dist;
            }
        }
        $faction->{'connected-sa-sh-distance'} = $distance;
    }

    if ($game{final_scoring}{'connected-clusters'}) {
        my %clique_clusters = ();
        for my $a (keys %clique) {
            my $clique = $clique{$a};
            my $cluster = $clusters{$a};
            $clique_clusters{$clique}{$cluster} = 1;
        }
        my @counts = map { scalar values %{$_} } values %clique_clusters;
        my $count = max @counts;
        $faction->{'connected-clusters'} = $count;
    }

    if ($game{final_scoring}{'building-on-edge'}) {
        my %clique_buildings_on_edge = ();
        for my $loc (keys %clique) {
            next if !$map{$loc}{edge};
            $clique_buildings_on_edge{$clique{$loc}}++;
        }
        my @counts = values %clique_buildings_on_edge;
        $faction->{'building-on-edge'} = (max @counts) // 0;
    }
}

# Given a faction, retrieve its total of trade markers spent.
sub compute_markers {	
	my $faction = shift;
	$faction->{'trade-markers'} = $faction->{MAX_TM} - $faction->{TM}
}

# The terraforming color wheel.
my @colors = qw(yellow brown black blue green gray red);
my %color_cycle = map { ($colors[$_], $_) } 0..$#colors;
my %colors = map { ($_ => 1) } @colors, qw(ice);

sub assert_color {
    for (@_) {
        die "Invalid color '$_'\n" if !exists $colors{$_};
    }
    
    @_;
}

sub color_difference {
    my ($a, $b) = assert_color @_;
    my $diff = $color_cycle{$b} - $color_cycle{$a};

    if ($diff > 3) {
        $diff -= 7;
    } elsif ($diff < -3) {
        $diff += 7;
    }

    return $diff;
}

sub alias_color {
    my $color = shift;
    if ($color eq "grey") {
        return "gray";
    }
    $color;
}

# Given a faction and a hex, figure out who can leach power when a
# building is built or upgraded, and how much. (Note: won't take into
# account the amount of power tokens the receiver has. That's taken
# care of when the power is received).
sub compute_leech {
    my ($from_faction, $where) = @_;
    my $color = $map{$where}{color};
    my %this_leech = ();

    return () if !$game{round};

    for my $adjacent (keys %{$map{$where}{adjacent}}) {
        my $map_color = $map{$adjacent}{color};
        my $type = $map{$adjacent}{building};
        if ($type and $map_color ne $color) {
            my ($to_faction) = grep {
                $_->{color} eq $map_color;
            } $game{acting}->factions_in_order(1);
            my $str = $to_faction->{building_strength}{$type} // $building_strength{$type};
            $this_leech{$map_color} += $str;
            $this_leech{$map_color} = $this_leech{$map_color};
        }
    }

    return %this_leech;
}

sub transform_colors_on_cycle {
    my ($current_color, $home_color, $spades) = @_;
    my $index = $color_cycle{$current_color};
    my ($cw, $ccw) = ($current_color, $current_color);

    for my $offset (1..$spades) {
        if ($cw ne $home_color) {
            $cw = $colors[($index + $offset) % 7];
        }
        if ($ccw ne $home_color) {
            $ccw = $colors[($index - $offset) % 7];
        }
    }

    if (abs color_difference($home_color, $cw) <
        abs color_difference($home_color, $ccw)) {
        return ($cw, $ccw);
    } else {
        return ($ccw, $cw);
    }
}

sub validate_transform_color {
    my ($faction, $where) = @_;
    my $current_color = $map{$where}{color};

    if ($current_color eq 'ice' or
        $current_color eq 'volcano') {
        die "Can't transform $current_color\n";
    }
}

sub transform_colors {
    my ($faction, $where) = @_;
    my $current_color = $map{$where}{color};

    validate_transform_color $faction, $where;

    if ($faction->{FREE_TF} or
        $faction->{color} eq 'volcano' or
        $faction->{name} eq 'giants') {
        return ($faction->{color}, undef);
    }

    my $spades = $faction->{SPADE};
    return ($current_color, $current_color) if !$spades;

    my $home_color = $faction->{color};
    my $secondary_color = $faction->{secondary_color};

    if ($secondary_color) {
        if ($current_color eq $secondary_color) {
            return ($home_color, $home_color);
        } else {
            my @a = map {
                $_ eq $secondary_color ? $home_color : $_
            } transform_colors_on_cycle $current_color, $secondary_color, $spades;            
            return @a;
        }
    } else {
        return transform_colors_on_cycle $current_color, $home_color, $spades;
    }
}

sub color_home_status {
    my ($color) = @_;
    my $hex_type = 'not_home';

    for my $other_faction ($game{acting}->factions_in_order()) {
        # The "color" of a faction with unlockable terrain is only the
        # color of the pieces, not actual home terrain.
        next if $other_faction->{locked_terrain};
        next if !defined $other_faction->{color};
        if ($other_faction->{color} eq $color) {
            $hex_type = 'home';
        }
    }

    $hex_type;
}

sub transform_cost {
    my ($faction, $where, $color) = @_;

    if (!$color) {
        ($color) = transform_colors $faction, $where;
    } else {
        validate_transform_color $faction, $where;
    }

    my $map_color = $map{$where}{color};
    my ($cost, $gain, $need_teleport) = check_reachable $faction, $where;

    my $color_difference;

    if ($color eq 'ice') {
        if ($map_color eq $faction->{secondary_color}) {
            $color_difference = 1;
        } else {
            $color_difference = abs color_difference $map_color, $faction->{secondary_color};
        }
    } elsif ($color eq 'volcano') {
        # Arbitrary, but must be non-zero.
        $color_difference = 7;
    } else {
        my $home_color = $faction->{secondary_color} // $faction->{color};
        my $color_diff = color_difference $map_color, $color;
        $color_difference = abs $color_diff;

        if ($game{options}{'loose-dig'}) {
            # Legacy game, just go the short way around.
        } elsif ($color eq $home_color or
                 $map_color eq $home_color) {
            # Transforming to or from home terrain, select the way
            # around color cycle that matches the number of remaining
            # spades.
            my $other_way = 7 - $color_difference;

            if ($faction->{SPADE} and $faction->{SPADE} == $other_way) {
                $color_difference = $other_way;
            }            
        } else {
            # Check that we're not crossing the home terrain when going
            # the short way around.
            my $home_diff = color_difference $map_color, $home_color;

            if ($home_diff < 0 != $color_diff < 0) {
                # Home terrain is in different direction from target ->
                # take the short way round.
            } elsif (abs $home_diff > abs $color_diff) {
                # Home terrain is further along the short direction than
                # target terrain.
            } else {
                # Home terrain intervenes, we must take the long way round.
                $color_difference = 7 - $color_difference;
            }
        }
    }

    if ($faction->{name} eq 'giants' and $color_difference != 0) {
        $color_difference = 2;
    }

    if ($color eq 'volcano') {
        $cost->{VOLCANO_TF} += 1;
        my $hex_type = color_home_status $map_color;
        my $effect = $faction->{volcano_effect}{$hex_type};
        for my $currency (keys %{$effect}) {
            my $amount = $effect->{$currency};
            if ($currency eq 'LOSE_PW_TOKEN') {
                if ($faction->{P1} + $faction->{P2} + $faction->{P3} < $amount) {
                    die "Not enough power for volcano\n";
                }
            } elsif ($currency eq 'LOSE_CULT') {
                my $ok = 0;
                for my $cult (@cults) {
                    $ok = 1 if $faction->{$cult} >= $amount;
                }
                die "Not high enough in any cult for volcano\n" if !$ok;
            }
            $cost->{$currency} -= $amount;
        }
    } elsif ($faction->{FREE_TF}) {
        $cost->{FREE_TF} += 1;
    } else {
        $cost->{SPADE} += $color_difference;
    }

    if ($faction->{TF_NEED_HEX_ADJACENCY}) {
        $cost->{TF_NEED_HEX_ADJACENCY} += 1;
        my $ok = 0;
        for my $from (@{$faction->{locations}}) {
            next if $map{$where}{bridge}{$from};
            if ($map{$where}{adjacent}{$from}) {
                $ok = 1;
                last;
            }
        }
        die "Direct non-bridge adjacency required for transforming\n" if !$ok;
    }

    ($cost, $gain, $need_teleport, $color_difference, $color)
}

sub build_color_ok {
    my ($faction, $color) = @_;
    
    return 1 if $faction->{color} eq $color;
    return 1 if $faction->{unlocked_terrain} and $faction->{unlocked_terrain}{$color};

    return 0;
}

sub update_reachable_build_locations {
    for my $faction ($game{acting}->factions_in_order()) {
        if ($game{acting}->is_active($faction)) {
            $faction->{reachable_build_locations} = [
                grep {
                    $_
                } map {
                    my $ret = 0;
                    my $loc = $_;
                    my $cost = {};
                    my $gain = {};
                    if (exists $map{$loc}{row} and
                        !$map{$loc}{building} and
                        build_color_ok $faction, $map{$loc}{color}) {
                        eval {
                            ($cost, $gain) = check_reachable $faction, $loc;
                            $ret = 1;
                        };
                    }
                    if ($ret) {
                        { hex => $loc, extra_cost => $cost, extra_gain => $gain }
                    }
                } keys %map
            ];
        } else {
            $faction->{reachable_build_locations} = [];
        }
    }
}

sub update_reachable_tf_locations {
    for my $faction ($game{acting}->factions_in_order()) {
        if ($game{acting}->is_active($faction) or
            ($faction->{passed} and $faction->{SPADE} > 0)) {
            my %res = ();

            for (keys %map) {
                my @res = ();
                my $loc = $_;

                next if !exists $map{$loc}{row} or $loc =~ /^r/;
                next if $map{$loc}{color} eq $faction->{color} or
                    $map{$loc}{building};

                my @colors = eval {
                    transform_colors $faction, $loc
                };
                next if $@;

                for my $color (@colors) {
                    next if !$color;

                    next if $faction->{require_home_terrain_tf} and $color ne $faction->{color};

                    my $cost = {};
                    my $gain = {};
                    my $color_diff = 0;
                    my $teleport = '';
                    eval {
                        ($cost, $gain, $teleport, $color_diff, $color) = transform_cost $faction, $loc, $color;
                    };
                    next if !$color_diff or !$color;
                    push @{$res{$loc}}, { hex => $loc, cost => $cost, gain => $gain, to_color => $color, teleport => $teleport };
                }
            }

            $faction->{reachable_tf_locations} = \%res;
        } else {
            $faction->{reachable_tf_locations} = [];
        }
    }
}

sub update_tp_upgrade_costs {
    for (keys %map) {
        if ($map{$_}{building} and
            $map{$_}{building} eq 'D') {
            my %neighbors = compute_leech undef, $_;
            $map{$_}{has_neighbors} = scalar keys %neighbors;
        }
    }
}

sub setup_map_aux {
    my ($base_map) = @_;
    my $reverse_map = {};
    setup_base_map $base_map, $reverse_map;
    setup_direct_adjacencies $reverse_map;
    setup_ranges $reverse_map;
    setup_valid_bridges $reverse_map;
}

sub setup_map {
    # A base map -> structured map cache.
    state $cache = {};

    my ($base_map) = @_;
    my $key = join ' ', @{$base_map};

    # The map will be mutated during game evaluation, be sure to return a
    # clone.
    clone $cache->{$key} ||= do {
        local %map;
        setup_map_aux $base_map;
        \%map;
    }
}

1;
