#!/usr/bin/perl -wl

package terra_mystica;

use strict;

use Clone qw(clone);

use vars qw(%game);
use vars qw(%map %reverse_map @bridges);

# Initialize %map, with the correct coordinates, from the above raw data.
sub setup_base_map {
    my $i = 0;
    my $ri = 0;
    my $river = 0;
    for my $row ('A'..'I') {
        my $col = 1;
        for my $ci (0..13) {
            my $color = $map[$i++];
            last if $color eq 'E';
            if ($color ne 'x') {
                $map{"$row$col"}{color} = $color;
                $map{"$row$col"}{row} = $ri;
                $map{"$row$col"}{col} = $ci;
                $reverse_map{$ri}{$ci} = "$row$col";
                $col++;
            } else {
                my $key = "r$river";
                $map{"$key"}{color} = 'white';
                $map{"$key"}{row} = $ri;
                $map{"$key"}{col} = $ci;
                $reverse_map{$ri}{$ci} = "$key";
                $river++;
            }
        }
        $ri++;
    }
}

# Set up the a list of directly adjacent hexes. Store it under the
# 'adjacent' hash key.
sub setup_direct_adjacencies {
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
        record_adjacent $coord, $reverse_map{$row}{$col+1};
        record_adjacent $coord, $reverse_map{$row}{$col-1};

        # Adjacent rows. Need to offset the column by one for every other
        # row.
        if ($row % 2 == 0) {
            $col--;
        }

        record_adjacent $coord, $reverse_map{$row - 1}{$col};
        record_adjacent $coord, $reverse_map{$row - 1}{$col + 1};
        record_adjacent $coord, $reverse_map{$row + 1}{$col};
        record_adjacent $coord, $reverse_map{$row + 1}{$col + 1};
    }
}

# For each hex, set up a hash table 'range' > other-hex > mode, stating
# the distance from that hex to other-hex, when traveling via mode.
# 1 for river, 0 for like the crow flies.
sub setup_hex_ranges {
    my ($from, $river_only) = @_;
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
    setup_hex_ranges $_, 0 for keys %map;
    setup_hex_ranges $_, 1 for keys %map;
}

sub setup_valid_bridges {
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
        if (($reverse_map{$row+1}{$offset_col} // '') =~ /^r/ and
            ($reverse_map{$row+1}{$offset_col+1} // '') =~ /^r/) {
            record_bridgable $coord, $reverse_map{$row+2}{$col};
        }

        # Adjacent row
        if (($reverse_map{$row}{$col-1} // '') =~ /^r/ and
            ($reverse_map{$row+1}{$offset_col} // '') =~ /^r/) {
            record_bridgable $coord, $reverse_map{$row+1}{$offset_col-1};
        }
        if (($reverse_map{$row}{$col+1} // '') =~ /^r/ and
            ($reverse_map{$row+1}{$offset_col+1} // '') =~ /^r/) {
            record_bridgable $coord, $reverse_map{$row+1}{$offset_col+2};
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

# Given a faction, compute the largest contiguous blob of buildings
# (taking into account river travel / teleporting).
sub compute_network_size {
    my $faction = shift;

    my @locations = @{$faction->{locations}};
    my %clique = ();
    my ($range, $ship);

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
                (exists $map{$loc}{range}{$ship}{$to} and
                 $map{$loc}{range}{$ship}{$to} <= $range)) {
                $handle->($to, $id);
            };
        }
    };

    # Trigger the search for each building.
    my $n = 1;
    $handle->($_, $n++) for @locations;

    # Find the clique with the most members.
    my %clique_sizes = ();
    $clique_sizes{$_}++ for values %clique;

    # And that's the size of the network.
    $faction->{network} = max values %clique_sizes;
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

sub color_at_offset {
    my ($color, $target, $max_steps) = @_;
    
    if ($max_steps == 0) {
        return $color;
    }

    my $difference = color_difference $color, $target;
    if ($difference <= $max_steps) {
        return $target;
    }

    my @colors_at_offset = grep {
        $max_steps == color_difference $color, $_ 
    } @colors;
    my @diff_to_target = map { color_difference $target, $_ } @colors_at_offset;

    if ($diff_to_target[0] < $diff_to_target[1]) {
        $colors_at_offset[0];
    } else {
        $colors_at_offset[1];
    }
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

sub transform_cost {
    my ($faction, $where, $color) = @_;

    if (!$color) {
        if ($faction->{FREE_TF}) {
            $color = $faction->{color};
        } elsif ($faction->{name} eq 'giants') {
            $color = $faction->{color};
        } else {
            $color = color_at_offset($map{$where}{color}, $faction->{color},
                                     $faction->{SPADE});
        }
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
            $faction->{reachable_tf_locations} = [
                grep {
                    $_
                } map {
                    my $ret = 0;
                    my $loc = $_;
                    my $cost = {};
                    my $gain = {};
                    my $color_diff = 0;
                    my $teleport = '';
                    my $color = '';
                    if (exists $map{$loc}{row} and
                        $map{$loc}{color} ne $faction->{color} and
                        !$map{$loc}{building}) {
                        eval {
                            ($cost, $gain, $teleport, $color_diff, $color) = transform_cost $faction, $loc, undef;
                        };
                    }
                    if ($color_diff and $color) {
                        { hex => $loc, cost => $cost, gain => $gain, to_color => $color, teleport => $teleport }
                    }
                } keys %map
            ];
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
    setup_base_map;
    setup_direct_adjacencies;
    setup_ranges;
    setup_valid_bridges;
}

1;
