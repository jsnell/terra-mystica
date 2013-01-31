package terra_mystica;

use strict;

use scoring;
use towns;
use tiles;

use vars qw(%pool);

our %pool = (
    # Resources
    C => 1000,
    W => 1000,
    P => 1000,
    VP => 1000,

    # Power
    P1 => 10000,
    P2 => 10000,
    P3 => 10000,

    # Cult tracks
    EARTH => 100,
    FIRE => 100,
    WATER => 100,
    AIR => 100,
    KEY => 100,

    # Temporary pseudo-resources for tracking activation effects
    SHOVEL => 10000,
    FREE_TF => 10000,
    FREE_TP => 10000,
    FREE_D => 10000,
    CULT => 10000,
    GAIN_FAVOR => 10000,
    GAIN_SHIP => 10000,
    GAIN_TW => 10000,
    CONVERT_W_TO_P => 3,
);

$pool{"ACT$_"}++ for 1..6;
$pool{"BON$_"}++ for 1..9;
$map{"BON$_"}{C} = 0 for 1..9;
$pool{"FAV$_"}++ for 1..4;
$pool{"FAV$_"} += 3 for 5..12;
$pool{"TW$_"} += 2 for 1..5;

sub adjust_resource;

my %resource_aliases = (
    PRIEST => 'P',
    PRIESTS => 'P',
    POWER => 'PW',
    WORKER => 'W',
    WORKERS => 'W',
    COIN => 'C',
    COINS => 'C',
);

sub alias_resource {
    my $type = shift;

    return $resource_aliases{$type} // $type;
}

sub pay {
    my ($faction_name, $cost) = @_;

    for my $currency (keys %{$cost}) {
        my $amount = $cost->{$currency};
        adjust_resource $faction_name, $currency, -$amount;
    }
}

sub gain {
    my ($faction_name, $cost) = @_;

    for my $currency (keys %{$cost}) {
        my $amount = $cost->{$currency};
        adjust_resource $faction_name, $currency, $amount;
    }
}

sub maybe_gain_faction_special {
    my ($faction_name, $type) = @_;
    my $faction = $factions{$faction_name};

    my $enable_if = $faction->{special}{enable_if};
    if ($enable_if) {
        for my $building (keys %{$enable_if}) {
            return if $faction->{buildings}{$building}{level} != $enable_if->{$building};
        }
    }

    gain $faction_name, $faction->{special}{$type};
}

sub gain_power {
    my ($faction_name, $count) = @_;
    my $faction = $factions{$faction_name};

    for (1..$count) {
        if ($faction->{P1}) {
            $faction->{P1}--;
            $faction->{P2}++;
        } elsif ($faction->{P2}) {
            $faction->{P2}--;
            $faction->{P3}++;
        } else {
            return $_ - 1;
        }
    }

    return $count;
}

sub maybe_gain_power_from_cult {
    my ($faction_name, $cult, $old_value, $new_value) = @_;
    my $faction = $factions{$faction_name};

    if ($old_value <= 2 && $new_value > 2) {
        adjust_resource $faction_name, 'PW', 1;
    }
    if ($old_value <= 4 && $new_value > 4) {
        adjust_resource $faction_name, 'PW', 2;
    }
    if ($old_value <= 6 && $new_value > 6) {
        adjust_resource $faction_name, 'PW', 2;
    }
    if ($old_value <= 9 && $new_value > 9) {
        if ($faction->{KEY} < 1) {
            $faction->{$cult} = 9;
            return;
        }

        adjust_resource $faction_name, 'KEY', -1;
        adjust_resource $faction_name, 'PW', 3;
        # Block others from this space
        for (@factions) {
            if ($_ ne $faction_name) {
                $factions{$_}{"MAX_$cult"} = 9;
            }
        }
    }
}

sub advance_track {
    my ($faction_name, $track_name, $track, $free) = @_;

    if (!$free) {
        pay $faction_name, $track->{advance_cost};
    }
    
    if ($track->{advance_gain}) {
        my $gain = $track->{advance_gain}[$track->{level}];
        gain $faction_name, $gain;
    }

    if (++$track->{level} > $track->{max_level}) {
        die "Can't advance $track_name from level $track->{level}\n"; 
    }
}

sub adjust_resource {
    my ($faction_name, $type, $delta) = @_;
    my $faction = $factions{$faction_name};

    $type = alias_resource $type;

    if ($type =~ 'GAIN_(TELEPORT|SHIP)') {
        my $track_name = lc $1;
        for (1..$delta) {
            my $track = $faction->{$track_name};
            my $gain = $track->{advance_gain}[$track->{level}];
            gain $faction_name, $gain;
            $track->{level}++
        }
        $type = '';
    } elsif ($type eq 'PW') {
        if ($delta > 0) {
            gain_power $faction_name, $delta;
            $type = '';
        } else {
            $faction->{P1} -= $delta;
            $faction->{P3} += $delta;
            $type = 'P3';
        }
    } else {
        my $orig_value = $faction->{$type};

        # Pseudo-resources not in the pool, but revealed by removing
        # buildings.
        if ($type !~ /^ACT.$/) {
            $pool{$type} -= $delta;
        }

        $faction->{$type} += $delta;

        if (exists $faction->{"MAX_$type"}) {
            my $max = $faction->{"MAX_$type"};
            if ($faction->{$type} > $max) {
                $faction->{$type} = $max;
            }
        }

        if (exists $pool{$type} and $pool{$type} < 0) {
            die "Not enough '$type' in pool\n";
        }

        if ($type =~ /^FAV/) {
            if (!$faction->{GAIN_FAVOR}) {
                die "Taking favor tile not allowed\n";
            } else {
                $faction->{GAIN_FAVOR}--;
            }

            gain $faction_name, $tiles{$type}{gain};

            # Hack
            if ($type eq 'FAV5') {
                for my $loc (@{$faction->{locations}}) {
                    detect_towns_from $faction_name, $loc;
                }
            }
        }

        if ($type =~ /^TW/) {
            if (!$faction->{GAIN_TW}) {
                die "Taking town tile not allowed\n";
            } else {
                $faction->{GAIN_TW}--;
            }
            gain $faction_name, $tiles{$type}{gain};
        }

        if (grep { $_ eq $type } @cults) {
            if ($faction->{CULT}) {
                $faction->{CULT} -= $delta;
            }

            my $new_value = $faction->{$type};
            maybe_gain_power_from_cult $faction_name, $type, $orig_value, $new_value;
        }

        for (1..$delta) {
            maybe_score_current_score_tile $faction_name, $type;
            maybe_gain_faction_special $faction_name, $type;
        }
    }

    if ($type =~ /^BON/) {
        $faction->{C} += $map{$type}{C};
        $map{$type}{C} = 0;
    }


    if ($type and $faction->{$type} < 0) {
        die "Not enough '$type' in $faction_name\n";
    }
}

1;
