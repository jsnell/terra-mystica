package terra_mystica;

use strict;

use scoring;
use towns;
use tiles;

use vars qw(%pool %bonus_coins $leech_id);

sub setup_pool {
    %bonus_coins = ();

    %pool = (
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
        SPADE => 10000,
        FREE_TF => 10000,
        FREE_TP => 10000,
        FREE_D => 10000,
        TELEPORT_NO_TF => 10000,
        CULT => 10000,
        GAIN_FAVOR => 10000,
        GAIN_SHIP => 10000,
        GAIN_TW => 10000,
        GAIN_ACTION => 10000,
        BRIDGE => 10000,
        CONVERT_W_TO_P => 3,
        TOWN_SIZE => 10000,
        );

    $pool{"ACT$_"}++ for 1..6;

    for (keys %tiles) {
        if (/^BON/) {
            $pool{$_}++;
            $bonus_coins{$_}{C} = 0;
        } elsif (/^FAV/) {
            $pool{$_} += $tiles{$_}{count} || 3;
        } elsif (/^TW/) {
            $pool{$_} += 2;
        }
    }
}

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
    my ($faction, $cost) = @_;

    for my $currency (keys %{$cost}) {
        my $amount = $cost->{$currency};
        adjust_resource $faction, $currency, -$amount;
    }
}

sub gain {
    my ($faction, $cost, $source) = @_;

    my @c = sort { $b eq 'KEY' } keys %{$cost};
    for my $currency (keys %{$cost}) {
        my $amount = $cost->{$currency};
        adjust_resource $faction, $currency, $amount, $source;
    }
}

sub maybe_gain_faction_special {
    my ($faction, $type) = @_;

    my $enable_if = $faction->{special}{enable_if};
    if ($enable_if) {
        for my $building (keys %{$enable_if}) {
            return if $faction->{buildings}{$building}{level} != $enable_if->{$building};
        }
    }

    gain $faction, $faction->{special}{$type}, 'faction';
}

sub gain_power {
    my ($faction, $count) = @_;

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
    my ($faction, $cult, $old_value, $new_value) = @_;

    if ($old_value <= 2 && $new_value > 2) {
        adjust_resource $faction, 'PW', 1;
    }
    if ($old_value <= 4 && $new_value > 4) {
        adjust_resource $faction, 'PW', 2;
    }
    if ($old_value <= 6 && $new_value > 6) {
        adjust_resource $faction, 'PW', 2;
    }
    if ($old_value <= 9 && $new_value > 9) {
        if ($faction->{KEY} < 1) {
            $faction->{$cult} = 9;
            return;
        }

        adjust_resource $faction, 'KEY', -1;
        adjust_resource $faction, 'PW', 3;
        # Block others from this space
        for (@factions) {
            if ($_ ne $faction->{name}) {
                $factions{$_}{"MAX_$cult"} = 9;
            }
        }
    }
}

sub advance_track {
    my ($faction, $track_name, $track, $free) = @_;

    if (!$free) {
        pay $faction, $track->{advance_cost};
    }
    
    if ($track->{advance_gain}) {
        my $gain = $track->{advance_gain}[$track->{level}];
        gain $faction, $gain, "advance_$track_name";
    }

    if (++$track->{level} > $track->{max_level}) {
        die "Can't advance $track_name from level $track->{level}\n"; 
    }
}

sub adjust_resource {
    my ($faction, $type, $delta, $source) = @_;

    $type = alias_resource $type;

    if ($type eq 'VP') {
        $faction->{vp_source}{$source || 'unknown'} += $delta;
    }

    if ($type =~ 'GAIN_(TELEPORT|SHIP)') {
        my $track_name = lc $1;
        for (1..$delta) {
            my $track = $faction->{$track_name};
            my $gain = $track->{advance_gain}[$track->{level}];
            gain $faction, $gain, "advance_$track_name";
            $track->{level}++
        }
        $type = '';
    } elsif ($type eq 'GAIN_ACTION') {
        $faction->{allowed_actions} += $delta;
        return;
    } elsif ($type eq 'PW') {
        if ($delta > 0) {
            gain_power $faction, $delta;
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
            if (!defined $pool{$type} or $pool{$type} < $delta) {
                die "Not enough '$type' in pool\n";
            }
            $pool{$type} -= $delta;
        }

        $faction->{$type} += $delta;

        if (exists $faction->{"MAX_$type"}) {
            my $max = $faction->{"MAX_$type"};
            if ($faction->{$type} > $max) {
                $faction->{$type} = $max;
            }
        }

        if ($type =~ /^FAV/) {
            if ($faction->{$type} > 1) {
                die "Can't take two copies of $type\n";
            }
            
            $faction->{stats}{$type}{round} = $round;
            $faction->{stats}{$type}{order} = scalar grep {/^FAV/} keys %{$faction};

            gain $faction, $tiles{$type}{gain}, $type;

            # Hack
            if ($type eq 'FAV5') {
                for my $loc (@{$faction->{locations}}) {
                    detect_towns_from $faction, $loc;
                }
            }
        }

        if ($type =~ /^TW/) {
            gain $faction, $tiles{$type}{gain}, 'TW';
        }

        if (grep { $_ eq $type } @cults) {
            my $new_value = $faction->{$type};
            maybe_gain_power_from_cult $faction, $type, $orig_value, $new_value;
        }

        for (1..$delta) {
            maybe_score_current_score_tile $faction, $type;
            maybe_gain_faction_special $faction, $type;
        }
    }

    if ($type =~ /^BON/) {
        $faction->{C} += $bonus_coins{$type}{C};
        $bonus_coins{$type}{C} = 0;
    }

    if ($type and $faction->{$type} < 0) {
        die "Not enough '$type' in ".($faction->{name})."\n";
    }
}

# Record any possible leech events from a build by a faction int the given
# hex. 
sub note_leech {
    my ($from_faction, $where) = @_;
    my %this_leech = compute_leech @_;
    $leech_id++;

    # Note -- the exact turn order matters when the cultists are in play.
    for my $faction_name (factions_in_order_from $from_faction->{name}) {
        my $faction = $factions{$faction_name};
        my $color = $faction->{color}; 
        next if !$this_leech{$color};
        my $amount = $this_leech{$color};
        my $actual = min $this_leech{$color}, $faction->{P1} * 2 + $faction->{P2};

        push @action_required, { type => 'leech',
                                 from_faction => $from_faction->{name},
                                 amount => $amount,
                                 actual => $actual,
                                 leech_id => $leech_id,
                                 faction => $faction->{name} };
    }

    for (keys %this_leech) {
	$leech{$_} += $this_leech{$_};
    }
}

1;
