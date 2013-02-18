#!/usr/bin/perl -wl

package terra_mystica;

use strict;

use factions;

use vars qw(%map %reverse_map @bridges);
our %map = ();
our %reverse_map = ();
our @bridges = ();

my @map = qw(brown gray green blue yellow red brown black red green blue red black E
             yellow x x brown black x x yellow black x x yellow E
             x x black x gray x green x green x gray x x E
             green blue yellow x x red blue x red x red brown E
             black brown red blue black brown gray yellow x x green black blue E
             gray green x x yellow green x x x brown gray brown E
             x x x gray x red x green x yellow black blue yellow E
             yellow blue brown x x x blue black x gray brown gray E
             red black gray blue red green yellow brown gray x blue green red E);

# Initialize %map, with the correct coordinates, from the above raw data.
sub setup_base_map {
    my $ri = 0;
    my $river = 0;
    for my $row ('A'..'I') {
        my $col = 1;
        for my $ci (0..13) {
            my $color = shift @map;
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
    my $max = ($river_only ? 6 : 2);

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

# Check whether a faction can reach a given hex (directly, by ship, or
# by teleporting).
#
# If the faction needs to teleport, also pay the teleport cost here.
sub check_reachable {
    my ($faction, $where) = @_;

    return if $round == 0;

    my $range = $faction->{ship}{level};
    if ($faction->{ship}{max_level}) {
        # XXX hack.
        $range++ if $faction->{BON4};
    }

    # Direct adjancies first (can't use tunneling / carpet flight bonus
    # if it isn't needed).
    for my $loc (@{$faction->{locations}}) {
        if ($map{$where}{adjacent}{$loc}) {
            return;
        }
    }

    # Ships
    if ($range) {
        for my $loc (@{$faction->{locations}}) {
            if (exists $map{$where}{range}{1}{$loc} and 
                $map{$where}{range}{1}{$loc} <= $range) {
                return;
            }
        }
    }

    if ($faction->{teleport}) {
        my $t = $faction->{teleport};
        my $level = $t->{level};
        my $range = $t->{range}[$level];

        # XXX: shouldn't do payment here.
        for my $loc (@{$faction->{locations}}) {
            if (exists $map{$where}{range}{0}{$loc} and 
                $map{$where}{range}{0}{$loc} <= $range) {
                my $cost = $t->{cost}[$level];
                my $gain = $t->{gain}[$level];
                pay($faction, $cost);
                gain($faction, $gain, 'faction');
                return;
            }
        }
    }

    die "$faction->{color} can't reach $where\n";
}

# Given a faction and a hex, return a list of all directly adjacent hexes
# that contain a building of that faction.
sub adjacent_own_buildings {
    my ($faction, $where) = @_;

    my @adjacent = keys %{$map{$where}{adjacent}};
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
        my $level = $t->{level};
        $range = $t->{range}[$level];
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

sub color_difference {
    my ($a, $b) = @_;
    my $diff = abs $colors{$a} - $colors{$b};

    if ($diff > 3) {
        $diff = 7 - $diff;
    }

    return $diff;
}

# Given a faction and a hex, figure out who can leach power when a
# building is built or upgraded, and how much. (Note: won't take into
# account the amount of power tokens the receiver has. That's taken
# care of when the power is received).
sub compute_leech {
    my ($from_faction, $where) = @_;
    my $color = $from_faction->{color};
    my %this_leech = ();

    return () if !$round;

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

setup_base_map;
setup_direct_adjacencies;
setup_ranges;

1;
