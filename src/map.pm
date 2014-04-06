#!/usr/bin/perl -wl

package terra_mystica;

use strict;

use Clone qw(clone);

use vars qw(%game);
use vars qw(%map);

# Initialize %map, with the correct coordinates, from the above raw data.
sub setup_base_map {
    my ($reverse_map) = @_;
    my @row_labels = 'A'..'Z';
    my $row_count = grep { $_ eq 'E' } @{$game{base_map}};

    my $i = 0;
    my $ri = 0;
    my $river = 0;
    for my $row (@row_labels[0..$row_count - 1]) {
        my $col = 1;
        for my $ci (0..13) {
            my $color = $game{base_map}[$i++];
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
        if (($reverse_map->{$row+1}{$offset_col} // '') =~ /^r/ and
            ($reverse_map->{$row+1}{$offset_col+1} // '') =~ /^r/) {
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

    return ({}, {}) if $game{round} == 0;

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
    for my $loc (@{$faction->{locations}}) {
        if ($map{$where}{adjacent}{$loc}) {
            return ({}, {});
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
            die "Can't use tunnel / carpet flight multiple times in one round\n"
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

    if ($game{final_scoring}{'buildings-on-edge'}) {
        my $count = 0;
        for my $loc (@{$faction->{locations}}) {
            $count++ if $map{$loc}{edge};
        }
        $faction->{'buildings-on-edge'} = $count;
    }
}

# The terraforming color wheel.
my @colors = qw(yellow brown black blue green gray red);
my %colors = map { ($colors[$_], $_) } 0..$#colors;

sub assert_color {
    for (@_) {
        die "Invalid color '$_'\n" if !exists $colors{$_};
    }
    
    @_;
}

sub color_difference {
    my ($a, $b) = assert_color @_;
    my $diff = abs $colors{$a} - $colors{$b};

    if ($diff > 3) {
        $diff = 7 - $diff;
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
        if ($map{$adjacent}{building} and
            $map_color ne $color) {
            $this_leech{$map_color} +=
                $building_strength{$map{$adjacent}{building}};
            $this_leech{$map_color} = $this_leech{$map_color};
        }
    }

    return %this_leech;
}

sub transform_colors {
    my ($faction, $where) = @_;
    if ($faction->{FREE_TF} or
        $faction->{name} eq 'giants') {
        return ($faction->{color}, undef);
    }

    my $current_color = $map{$where}{color};
    my $home_color = $faction->{color};

    return ($current_color, $current_color) if !$faction->{SPADE};

    my $index = $colors{$current_color};
    my ($cw, $ccw) = ($current_color, $current_color);

    for my $offset (1..$faction->{SPADE}) {
        if ($cw ne $home_color) {
            $cw = $colors[($index + $offset) % 7];
        }
        if ($ccw ne $home_color) {
            $ccw = $colors[($index - $offset) % 7];
        }
    }

    if (color_difference($cw, $home_color) <
        color_difference($ccw, $home_color)) {
        return ($cw, $ccw);
    } else {
        return ($ccw, $cw);
    }
}

sub transform_cost {
    my ($faction, $where, $color) = @_;

    if (!$color) {
        ($color) = transform_colors $faction, $where;
    }

    my ($cost, $gain, $need_teleport) = check_reachable $faction, $where;

    my $color_difference = color_difference $map{$where}{color}, $color;

    if ($faction->{name} eq 'giants' and $color_difference != 0) {
        $color_difference = 2;
    }

    if ($faction->{FREE_TF}) {
        $cost->{FREE_TF} += 1;
        my $ok = 0;
        for my $from (@{$faction->{locations}}) {
            next if $map{$where}{bridge}{$from};
            if ($map{$where}{adjacent}{$from}) {
                $ok = 1;
                last;
            }
        }
        die "ActN requires direct non-bridge adjacency" if !$ok;
    } else {
        $cost->{SPADE} += $color_difference;
    }

    ($cost, $gain, $need_teleport, $color_difference, $color)
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
                        $map{$loc}{color} eq $faction->{color} and
                        !$map{$loc}{building}) {
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

                for my $color (transform_colors $faction, $loc) {
                    next if !$color;

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

sub setup_map {
    my $reverse_map = {};
    setup_base_map $reverse_map;
    setup_direct_adjacencies $reverse_map;
    setup_ranges $reverse_map;
    setup_valid_bridges $reverse_map;
}

1;
