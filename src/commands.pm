package terra_mystica;

use strict;

use Digest::SHA qw(sha1);
use Math::Random::MT;

use Game::Constants;
use Game::Factions;

use buildings;
use map;
use income;
use ledger;
use resources;
use scoring;
use towns;

use vars qw(%game);

sub handle_row;
sub handle_row_internal;

sub command_adjust_resources {
    my ($faction, $delta, $type, $source) = @_;
    my $faction_name = $faction->{name};
    my $ledger = $game{ledger};
    my $checked = 0;

    if (grep { $_ eq $type } @cults) {
        if ($faction->{CULT} < $delta) {
            if ($faction->{$type} == 10) {
                $checked = 1;
            } elsif ($faction->{cult_blocked} and
                       $faction->{cult_blocked}{$type} and
                       $faction->{KEY}) {
                $checked = 1;
            } else {
                # die "Advancing $delta steps on $type cult not allowed\n";
            }
        } elsif ($delta < 0) {
            if ($faction->{LOSE_CULT}) {
                my $loss = -$delta;
                if ($faction->{LOSE_CULT} != $loss) {
                    die "All cult steps must be lost on the same cult track\n";
                }
                if ($faction->{$type} < $loss) {
                    die "Not high enough on $type to lose $loss steps";
                }
                $faction->{LOSE_CULT} -= $loss;
                $checked = 1;
            } elsif (!$game{options}{'loose-cult-loss'}) {
                my $old_value = $faction->{$type};
                my $new_value = $old_value + $delta;
                # Only allow the kind of adjustment needed to work around the 
                # TW5 issue.
                if ($old_value == 10 or
                    ($new_value < 7)) {
                    die "Can't voluntarily lose cult steps\n";
                }
            }
        } elsif ($faction->{CULT} > $delta and
                 $faction->{CULTS_ON_SAME_TRACK}) {
            die "All cult advances must be used on the same cult track\n";
        } else {
            $faction->{CULT} -= $delta;
            $checked = 1;
            delete $faction->{CULTS_ON_SAME_TRACK};
        }
    } elsif ($faction->{LOSE_CULT}) {
        unless ($game{options}{'loose-lose-cult'}) {
            die "Must lose $faction->{LOSE_CULT} cult steps first\n";
        }
    }

    if ($type =~ /^FAV/) {
        if (!$faction->{GAIN_FAVOR}) {
            die "Taking favor tile not allowed\n";
        } else {
            $faction->{GAIN_FAVOR} -= $delta;
            $checked = 1;
        }
    }

    if ($type =~ /^TW/) {
        if (!$faction->{GAIN_TW}) {
            die "Taking town tile not allowed\n";
        } else {
            $faction->{GAIN_TW} -= $delta;
            $checked = 1;
        }
    }

    if ($type eq 'VP' and $game{finished}) {
        $checked = 1;
    }

    if ($type eq 'SPADE' and $delta < 0) {
        if (!$faction->{passed} and
            $faction->{disable_spade_decline} and
            !$game{options}{'loose-dig'}) {
            die "All spades from 'dig' command must be used, can't be thrown away.\n";
        }
        $checked = 1;
    }

    if (!$checked and $delta > 0 or
        # Having a blacklist doesn't feel right, but it's simpler than a
        # whitelist. (And is needed since some of these things you can
        # decline).
        $type =~ /^(LOSE_|CULTS_ON_SAME_TRACK|TOWN_SIZE|TF_NEED_HEX_ADJACENCY)/) {
        if ($game{options}{'loose-adjust-resource'} or
            $faction->{planning}) {
            $ledger->warn("dodgy resource manipulation ($delta $type)");
            $game{dodgy_resource_manipulation} = 1;
        } else {
            die "Not allowed to gain $delta x $type\n";
        }
    }

    adjust_resource $faction, $type, $delta, $source;

    # If you decline the Nomad or Witch SH power, the extra restrictions
    # the terraform / build would have need to be removed as well.
    if ($type eq 'FREE_TF' and $faction->{$type} == 0) {
        delete $faction->{TF_NEED_HEX_ADJACENCY};
    }
    if ($type eq 'FREE_D' and $faction->{$type} == 0) {
        delete $faction->{TELEPORT_NO_TF};
    }

    # Small hack: always remove the notifier for a cultist special cult
    # increase. Needs to be done like this, since we don't want + / - to
    # count as full actions.
    $game{acting}->dismiss_action($faction, 'cult');

    # Handle throwing away spades with "-SPADE", e.g. if you are playing
    # Giants.
    if ($type eq 'SPADE' and $faction->{SPADE} < 1) {
        $game{acting}->dismiss_action($faction, 'transform');
    }

    if ($type =~ /^GAIN_/) {
        $game{acting}->dismiss_action($faction, 'gain-token');
    }
}

sub command_build {
    my ($faction, $where) = @_;
    my $faction_name = $faction->{name};

    my $free = ($game{round} == 0);
    my $type = 'D';
    my $color = $faction->{color};

    die "Unknown location '$where'\n" if !$map{$where};

    die "'$where' already contains a $map{$where}{building}\n"
        if $map{$where}{building};

    if ($faction->{FREE_D}) {
        $free = 1;
        $faction->{FREE_D}--;
    }

    if ($game{round} == 0 and $faction->{name} eq 'riverwalkers' and
        keys %{$map{$where}{range}{1}} <= 1) {
        die "Can't place initial dwelling inland for $faction->{name}.\n";
    }

    my $tf_needed = !build_color_ok $faction, $map{$where}{color};

    # Check that we haven't transformed one location, and are trying to
    # build on another.
    my $check_if_build_location_allowed_after_tf = !$tf_needed;

    # We've already done all the allowed transforms (2 if using a bare act6
    # with no added digs, 1 otherwise). We need to check that the build
    # is happening in one of the transformed spaces, if the build is to happen
    # on the same action.
    if (!$game{options}->{'loose-build-after-dig'} and
        !$faction->{allowed_sub_actions}{transform}) {
        $check_if_build_location_allowed_after_tf = 1;
    }

    if ($check_if_build_location_allowed_after_tf) {
        # Only allow building in this location if:
        #   - The user has a full new action available (achieved by
        #     deleting any available build subaction).
        #   - They're doing a build rather than tranform and build
        #     (the first subexpression takes care of that).
        #   - They already transformed this specific location
        if (keys %{$faction->{allowed_build_locations}} and
            !$faction->{allowed_build_locations}{$where}) {
            delete $faction->{allowed_sub_actions}{build};
        }
    }

    if (!$tf_needed) {
        $map{$where}{color} = $color;
    }

    $game{acting}->require_subaction($faction, 'build', {
        transform => $tf_needed
    });

    if ($faction->{TELEPORT_NO_TF}) {
        $faction->{TELEPORT_NO_TF}--;
        die "Transforming terrain forbidden during this action\n"
            if $tf_needed;
    } else {
        if ($tf_needed) {
            if ($game{round} == 0 and
                $map{$where}{color} eq $faction->{secondary_color}) {
                $map{$where}{color} = $color;
            } else {
                
                command $faction_name, "transform $where to $color";
            }
        } else {
            my ($cost, $gain, $teleport) = check_reachable $faction, $where;
            if ($teleport) {
                $faction->{TELEPORT_TO} = $where;
            }
            pay $faction, $cost;
            gain $faction, $gain, 'faction';
        }
    }

    if ($faction->{SPADE} > 0) {
        die "Must do all transforms before building ($faction->{SPADE} spades) remaining\n";
    }

    if (!$game{round}) {
        $game{acting}->setup_action($faction_name, 'build');
        $game{ledger}->force_finish_row(1);
    }

    note_leech $faction, $where;

    advance_track $faction, $type, $faction->{buildings}{$type}, $free;

    if ($game{round}) {
        maybe_score_favor_tile $faction, $type;
        maybe_score_current_score_tile $faction, $type, 'build';
    }

    $map{$where}{building} = $type;

    push @{$faction->{locations}}, $where;

    detect_towns_from $faction, $where;

    $game{events}->faction_event($faction, 'build:D', 1);
    $game{events}->location_event($faction, $where);
}

sub command_upgrade {
    my ($faction, $where, $type) = @_;

    $game{acting}->require_subaction($faction, 'upgrade', {});

    die "Unknown location '$where'\n" if !$map{$where};

    my $color = $faction->{color};
    die "$where has wrong color ($color vs $map{$where}{color})\n" if
        $map{$where}{color} ne $color;

    my %wanted_oldtype = (TP => 'D', TE => 'TP', SH => 'TP', SA => 'TE');
    my $oldtype = $map{$where}{building};

    if (!$wanted_oldtype{$type}) {
        die "unknown building type $type\n";
    }

    if ($oldtype ne $wanted_oldtype{$type}) {
        die "$where contains $oldtype, wanted $wanted_oldtype{$type}\n"
    }

    my %this_leech = note_leech $faction, $where;

    my $free = 0;
    if ($type eq 'TP') {
        if ($faction->{FREE_TP}) {
            $free = 1;
            $faction->{FREE_TP}--;
        } else {
            if (!keys %this_leech) {
                my $cost = $faction->{buildings}{$type}{advance_cost}{C};
                adjust_resource $faction, "C", -${cost};
            }
        }
    }

    if (defined $faction->{buildings}{$type}{subactions}) {
        $faction->{allowed_sub_actions} =
            $faction->{buildings}{$type}{subactions};
    }

    $faction->{buildings}{$oldtype}{level}--;
    advance_track $faction, $type, $faction->{buildings}{$type}, $free;

    maybe_score_favor_tile $faction, $type;
    maybe_score_current_score_tile $faction, $type, 'build';

    $map{$where}{building} = $type;

    detect_towns_from $faction, $where;

    $game{events}->faction_event($faction, "upgrade:$type", 1);
}

sub command_send {
    my ($faction, $cult, $amount) = @_;

    $game{acting}->require_subaction($faction, 'send', {});

    die "Unknown cult track $cult\n" if !grep { $_ eq $cult } @cults;

    my $gain = { $cult => 1 };
    for (1..4) {
        my $where = "$cult$_";
        my $spot = $game{cults}{$where};
        if (!$spot->{building}) {
            if ($amount) {
                next if $spot->{gain}{$cult} != $amount;
            }

            $gain = clone $spot->{gain};
            delete $spot->{gain};
            $spot->{building} = 'P';
            $spot->{color} = $faction->{color};
            $faction->{MAX_P}--;
            $faction->{CULT_P}++;
            last;
        }
    }

    if ($amount) {
        die "No $amount spot on $cult track\n" if $gain->{$cult} != $amount;
    }

    $gain->{$cult} += ($faction->{PRIEST_CULT_BONUS} // 0);

    gain $faction, $gain;

    $game{events}->faction_event($faction, "send:$cult", 1);

    adjust_resource $faction, "P", -1;
}

sub command_convert {
    my ($faction,
        $from_count, $from_type,
        $to_count, $to_type) = @_;

    my %exchange_rates = ();

    if (!$game{options}->{'loose-convert-phase'} and
        !$faction->{planning} and
        $game{acting}->state() ne 'play') {
        die "Can't convert resources outside of actions\n";
    }

    if ($from_type eq 'P' and $to_type eq 'C'
        and $faction->{P3}) {
        preview_warn("Converting priest to coins, despite power in bowl 3");
    }

    # Have to leech before converting resources
    my @records = leech_decisions_required($faction);
    for (@records) {
        $_->{leech_tainted} = 'convert';
    }

    for my $from_key (keys %{$faction->{exchange_rates}}) {
        my $from = $faction->{exchange_rates}{$from_key};
        for my $to_key (keys %{$from}) {
            $exchange_rates{$from_key}{$to_key} = $from->{$to_key};
        }
    }

    if ($faction->{CONVERT_W_TO_P}) {
        die "Can't convert more than 3 W to P\n" if $to_count > 3;
        $exchange_rates{W}{P} = 1;
        delete $faction->{CONVERT_W_TO_P};
    }

    die "Can't convert from $from_type to $to_type\n"
        if !$exchange_rates{$from_type}{$to_type};

    my $wanted_from_count =
        $to_count * $exchange_rates{$from_type}{$to_type};
    die "Conversion to $to_count $to_type requires $wanted_from_count $from_type, not $from_count\n"
        if  $wanted_from_count != $from_count;

    adjust_resource $faction, $from_type, -$from_count, "convert";
    adjust_resource $faction, $to_type, $to_count, "convert";
}

sub command_gain {
    my ($faction,
        $to_type,
        $from_type) = @_;
    my $field = "GAIN_${to_type}_FOR_${from_type}";

    if (!$faction->{$field}) {
        die "Can't gain ${to_type} for ${from_type}\n";
    }

    adjust_resource $faction, $from_type, -1, "convert";
    adjust_resource $faction, $to_type, 1, "convert";

    --$faction->{$field};

    $game{acting}->dismiss_action($faction, 'gain-token');    
}

sub command_leech {
    my ($faction, $pw, $from) = @_;
    my $faction_name = $faction->{name};
    my $ledger = $game{ledger};

    my $actual_pw = $pw;
    if ($actual_pw > $faction->{VP}) {
        $actual_pw = $faction->{VP} + 1;
    }
    $actual_pw = gain_power $faction, $actual_pw;
    my $vp = $actual_pw - 1;

    my $found_leech_record = 0;
    my @detect_incomplete_turn_for = ();

    for (@{$game{acting}->action_required()}) {
        next if $_->{faction} ne $faction_name;
        next if $_->{type} ne 'leech';
        
        if (($_->{amount} ne $pw and $_->{amount} ne $actual_pw) or
            ($from and $from ne $_->{from_faction})) {
            $_->{leech_tainted} =
                "leech $pw from $from";
            next;
        }

        my $from_faction = $game{acting}->get_faction($_->{from_faction});
        if ($from_faction->{leech_effect} and
            $_->{actual} > 0) {
            if (!$from_faction->{leech_cult_gained}{$_->{leech_id}}++) {
                $game{ledger}->add_row_for_effect(
                    $from_faction,
                    "[opponent accepted power]",
                    sub {
                        gain $from_faction, $from_faction->{leech_effect}{taken};
                    });
                
                push @detect_incomplete_turn_for, [ $from_faction, $from_faction->{leech_effect}{taken} ];
                $game{events}->faction_event($from_faction, 'cultist:cult', 1);
            }
            $game{events}->faction_event($faction, 'leech-from-cultist:pw',
                                         $actual_pw);
            $game{events}->faction_event($faction, 'leech-from-cultist:count',
                                         1);
        }

        if ($_->{leech_tainted}) {
            my $err = "'leech $pw from $from' should happen before '$_->{leech_tainted}'";
            if ($game{options}{'strict-leech'}) {
                die "$err\n";
            } else {
                $ledger->warn($err);
            }
        }

        $_ = '';
        $found_leech_record = 1;
        last;
    }

    if (!$found_leech_record) {
        if (!$from and !$game{options}{'strict-leech'}) {
            $ledger->warn("invalid leech $pw (accepting anyway)");
        } else {
            die "invalid leech $pw from $from\n";
        }
    }

    if ($actual_pw > 0) {
	adjust_resource $faction, 'VP', -$vp, 'leech';
    }

    for my $record (@detect_incomplete_turn_for) {
        $game{acting}->detect_incomplete_turn($record->[0]);
    }
    $game{acting}->clear_empty_actions();

    my $can_gain = min $faction->{P1} * 2 + $faction->{P2};
    for my $record (@{$game{acting}->action_required()}) {
        if ($record->{type} eq 'leech' and
            $record->{faction} eq $faction_name) {
            if (!$can_gain and $record->{actual}) {
                my $from_faction = $game{acting}->get_faction($record->{from_faction});
                my $leech_id = $record->{leech_id};
                cultist_maybe_gain_power($record);
            }
            $record->{actual} = min $record->{actual}, $can_gain;
        }
    }

    if ($actual_pw) {
        $game{events}->faction_event($faction, 'leech:pw', $actual_pw);
        $game{events}->faction_event($faction, 'leech:count', 1);
    }
}

sub command_decline {
    my ($faction, $amount, $from) = @_;
    my $declined = 0;

    if (!$amount) {
        # Decline all
        my @declines = grep {
            $_->{faction} eq $faction->{name} and $_->{type} eq 'leech';
        } @{$game{acting}->action_required()};
        for (@declines) {
            $declined +=
                command_decline($faction, $_->{amount}, $_->{from_faction});
        }
    } else {
        for (@{$game{acting}->action_required()}) {
            if ($_->{faction} eq $faction->{name} and
                $_->{type} eq 'leech' and
                $_->{amount} eq $amount and
                $_->{from_faction} eq $from) {
                my $from_faction = $game{acting}->get_faction($_->{from_faction});
                my $leech_id = $_->{leech_id};
                $from_faction->{leech_rejected}{$leech_id}++;
                cultist_maybe_gain_power($_);
                if ($_->{actual} > 0) {
                    $game{events}->faction_event($faction, 'decline:count', 1);
                    $game{events}->faction_event($faction, 'decline:pw', $_->{actual});
                    if ($from_faction->{leech_effect}) {
                        $game{events}->faction_event($faction, 'decline-from-cultist:count', 1);
                        $game{events}->faction_event($faction, 'decline-from-cultist:pw', $_->{actual});                        
                    }
                }
                $_ = '';
                $declined = 1;
                last;
            }
        }
        $game{acting}->clear_empty_actions();
        die "Invalid decline ($amount from $from)\n" if !$declined;
    }

    return $declined;
}

sub cultist_maybe_gain_power {
    my $record = shift;
    my $faction = $game{acting}->get_faction($record->{from_faction});

    # A decline of a 0 power gain has no effect. (Note that leech_not_rejected
    # has been setup with this assumption in mind).
    return if !$record->{actual};
    # Somebody still hasn't made a decision on leeching from this event
    return if --$faction->{leech_not_rejected}{$record->{leech_id}} > 0;
    # Nobody has yet rejected any power from this leech event. How could this
    # happen, you might ask, since we're only calling this function due to
    # somebody just rejecting power. It could happen because a leeching
    # opportunity was retroactively converted to have an actual value of 0,
    # due another leech getting resolved.
    return if $faction->{leech_rejected}{$record->{leech_id}} == 0;
    # Of course all of this only matters for the cultists and shapeshifters.
    return if !$faction->{leech_effect};
    # And when playing with the new rule.
    return if !$game{options}{'errata-cultist-power'};

    $game{ledger}->add_row_for_effect(
        $faction,
        "[all opponents declined power]",
        sub {
            gain $faction, $faction->{leech_effect}{not_taken};
        });

    $game{events}->faction_event($faction, 'cultist:pw', 1);
}

sub command_transform {
    my ($faction, $where, $color) = @_;
    my $faction_name = $faction->{name};

    if (defined $color) {
        $color = alias_color $color;
    }

    my ($transform_cost,
        $transform_gain,
        $teleport,
        $color_difference,
        @valid_colors) = transform_cost $faction, $where, $color;

    if (!$color) {
        $color = $valid_colors[0];
    }

    if ($map{$where}{color} eq $color) {
        die "Can't transform $where, it already is $color\n"
    }

    if ($map{$where}{building}) {
        die "Can't transform $where to $color, already contains a building\n"
    }

    if ($color_difference) {
        if (!$faction->{passed}) {
            $game{acting}->require_subaction($faction, 'transform', {
                transform => ($faction->{allowed_sub_actions}{transform} // 1) - 1,
                build => $faction->{allowed_sub_actions}{build} // 0,
            });
        }
        if (!$game{options}{'loose-multi-spade'} and
            $faction->{require_home_terrain_tf} and
            $color ne $faction->{color}) {
            die "Can't transform more than one hex to non-home color in one action\n";
        }
    }

    if ($teleport) {
        $faction->{TELEPORT_TO} = $where;
    }
    pay $faction, $transform_cost;
    gain $faction, $transform_gain, 'faction';

    for my $type (keys %{$transform_cost}) {
        my $amount = $transform_cost->{$type};
        for (1..$amount) {
            maybe_score_current_score_tile $faction, $type, 'spend';
            maybe_gain_faction_special $faction, $type, 'spend';
        }
    }

    delete $faction->{require_home_terrain_tf};

    if (!$faction->{SPADE}) {
        $game{acting}->dismiss_action($faction, 'transform');
        delete $faction->{allowed_sub_actions}{transform};
        delete $faction->{require_home_terrain_tf};
    } else {
        for my $record ($game{acting}->find_actions($faction, 'transform')) {
            $record->{amount} = $faction->{SPADE};
        }
        if ($color ne $faction->{color} and !$faction->{passed}) {
            $faction->{require_home_terrain_tf} = 1;
            if (!$faction->{allowed_sub_actions}{transform} and
                !$game{options}{'loose-dig'}) {
                die "Must use all available spades when transforming a hex to non-home color using spades from a 'dig' command ($faction->{SPADE} spades remaining)\n";
            }
        }
    }

    if ($color eq $faction->{color}) {
        $faction->{allowed_build_locations}{$where} = 1;
    }

    $map{$where}{color} = $color;

    detect_towns_from $faction, $where;
}

sub command_dig {
    my ($faction, $amount) = @_;

    if (!$faction->{dig}) {
        die "$faction->{display} can't use 'dig'\n";
    }

    my $cost = $faction->{dig}{cost}[$faction->{dig}{level}];
    my $gain = $faction->{dig}{gain}[$faction->{dig}{level}];

    if (!$game{options}{'loose-dig'} or
        !$faction->{allowed_sub_actions}{transform}) {
        $game{acting}->require_subaction($faction, 'dig', {
            transform => 1,
            build => 1,
            dig => 1,
        });
    }

    if (!$gain) {
        adjust_resource $faction, 'SPADE', $amount;
    }
    pay $faction, $cost for 1..$amount;
    gain $faction, $gain, 'faction' for 1..$amount;

    $faction->{disable_spade_decline} = 1;

    $game{events}->faction_event($faction, 'dig', $amount);
}

sub faction_has_building_in {
    my ($faction, $where) = @_;
    return $map{$where}{building} &&
        $map{$where}{color} eq $faction->{color};
}

sub command_bridge {        
    my ($faction, $from, $to, $allow_illegal) = @_;

    if (!$faction->{BRIDGE}) {
        die "Can't build bridge\n";
    }
    
    if (!$game{options}{'loose-bridge-adjacency'} and
        !(faction_has_building_in $faction, $from or
          faction_has_building_in $faction, $to)) {        
        die "Bridge must be adjacent to at least one building\n";
    }

    $game{acting}->require_subaction($faction, 'bridge', {
        bridge => $faction->{BRIDGE} - 1,
    });

    if (!$allow_illegal) {
        if ($faction->{BRIDGE_COUNT} == 0) {
            die "All 3 bridges already placed";
        }
        if (!$map{$from}{bridgable}{$to}) {
            die "Can't build bridge from $from to $to\n";
        }
    }

    $faction->{BRIDGE_COUNT}--;

    $map{$from}{adjacent}{$to} = 1;
    $map{$to}{adjacent}{$from} = 1;

    $map{$from}{bridge}{$to} = 1;
    $map{$to}{bridge}{$from} = 1;

    if (!--$faction->{BRIDGE}) {
        delete $faction->{BRIDGE};
    }

    push @{$game{bridges}}, {from => $from, to => $to, color => $faction->{color}};

    detect_towns_from $faction, $from;
    detect_towns_from $faction, $to;

    $game{events}->faction_event($faction, 'bridge', 1);
}

sub find_bonus_to_discard {
    my ($faction, $bon) = @_;

    for (keys %{$faction}) {
        next if !$faction->{$_};

        if (/^BON/) {
            return $_;
        }
    }

    undef;
}

sub command_pass {
    my ($faction, $bon) = @_;
    my $faction_name = $faction->{name};
    my $ledger = $game{ledger};

    if ($game{options}{'strict-chaosmagician-sh'} and
        $faction->{allowed_actions} > 1) {
        $faction->{allowed_actions} = 1;
    }

    $game{acting}->require_subaction($faction, 'pass', {});

    my $passed_count = grep { $_->{passed} } $game{acting}->factions_in_order();

    my $first_to_pass = $passed_count == 0;

    if ($game{round}) {
        if ($first_to_pass) {
            $_->{start_player} = 0 for $game{acting}->factions_in_order();
            $faction->{start_player} = 1;
        }

        if ($game{options}{'variable-turn-order'}) {
            my @other_factions = grep {
                $_->{name} ne $faction->{name}
            } $game{acting}->factions_in_order(0);
            $game{acting}->new_faction_order([@other_factions, $faction]);
        }
    }

    if ($game{options}{'strict-chaosmagician-sh'} and $faction->{passed}) {
        die "Can't pass multiple times in one round\n";
    }

    $faction->{passed} = 1;
    my $discard = find_bonus_to_discard $faction;

    do_pass_vp $faction, sub {
        adjust_resource $faction, 'VP', $_[0], $_[1];
    };

    if ($bon) {
        if (!$game{round}) {
            $game{acting}->setup_action($faction, 'pass');
        }

        if ($game{round} == 6) {
            $ledger->warn("Can't take a bonus tile when passing on last round\n");
        } else {
            adjust_resource $faction, $bon, 1;
            $game{events}->faction_event($faction, "pass:$bon", 1);
        }
    } elsif ($game{round} != 6) {
        die "Must take a bonus tile when passing (except on last round)\n"
    }

    if ($discard) {
        adjust_resource $faction, $discard, -1;
    }

    if ($game{round} != 6) {
        my $income = faction_income $faction;
        for my $subincome (@{$income->{ordered}}) {
            warn_if_cant_gain $faction, $subincome, 'income';
        }
    }
}

sub command_action {
    my ($faction, $action) = @_;
    my $faction_name = $faction->{name};

    if ($action !~ /^ACT[1-6]/ and !$faction->{$action}) {
        die "No $action space available\n"
    }    
    my $name = $action;
    my $ar;

    if (exists $faction->{actions} and
        exists $faction->{actions}{$name}) {
        $ar = $faction->{actions}{$name};
    } elsif (exists $actions{$name}) {
        $ar = $actions{$name};
    } else {
        die "Unknown action $name\n";
    }

    if ($action !~ /^ACT/) {
        $action .= "/$faction_name";
    }

    if ($map{$action}{blocked} && !
        $faction->{allow_reuse}{$action}) {
        die "Action space $action is blocked\n"
    }

    if (exists $faction->{action} and
        $faction->{action}{$name}{forbid}) {
        die "$faction->{display} are not allowed to use action $name\n";
    }

    my %subaction = ();

    if (exists $faction->{action} and
        exists $faction->{action}{$name}{subaction}) {
        %subaction = %{$faction->{action}{$name}{subaction}};
    } elsif (exists $ar->{subaction}) {
        %subaction = %{$ar->{subaction}};
    }

    $game{acting}->require_subaction($faction, 'action', \%subaction);

    pay $faction, $ar->{cost}, ($faction->{discount} and $faction->{discount}{$name});
    warn_if_cant_gain $faction, $ar->{gain}, "action $action";
    gain $faction, $ar->{gain}, $name;

    $map{$action}{blocked} = 1 unless $ar->{dont_block};

    $game{events}->faction_event($faction, "action:$name", 1);
}

sub command_start {
    my $ledger_state = $game{ledger};
    $game{round}++;
    $game{turn} = 1;
    $ledger_state->{printed_turn} = 0;

    for my $faction ($game{acting}->factions_in_order()) {
        die "Round $game{round} income not taken for $faction->{name}\n" if
            !$faction->{income_taken};
        $faction->{income_taken} = 0;
        $faction->{passed} = 0;
    }

    $map{$_}{blocked} = 0 for keys %map;
    for (keys %{$game{pool}}) {
        next if !/^BON/;
        next if !$game{pool}{$_};
        $game{bonus_coins}{$_}{C}++;
    }

    $game{ledger}->turn($game{round}, $game{turn});

    my @order = $game{acting}->factions_in_turn_order();
    my $i = 0;
    for my $faction (@order) {
        $faction->{order} = $i++;
        $game{events}->faction_event($faction, "order:$i", 1);
    }

    for (@order ){
        my $start_player = $_;
        next if $start_player->{dropped};

        $game{acting}->require_action($start_player,
                                      { type => 'full' });
        $game{acting}->start_full_move($start_player);
        $game{acting}->full_turn_played(0);
        last;
    }

    $game{events}->global_event($game{score_tiles}[$game{round} - 1], 1);
}

sub command_connect {
    my ($faction, @hexes) = @_;
    my $faction_name = $faction->{name};

    die "Only mermaids can use 'connect'\n" if $faction_name ne 'mermaids';

    @hexes = grep { $_ ne '' } @hexes;

    my %rivers = ();

    for my $hex (@hexes) {
        for my $adjacent (keys %{$map{$hex}{adjacent}}) {
            if ($adjacent =~ /^r/) {
                $rivers{$adjacent}++;
            }
        }
    }

    for my $river (keys %rivers) {
        next if $rivers{$river} != @hexes;

        my @land = grep { !/^r/ } keys %{$map{$river}{adjacent}};

        for my $from (@land) {
            for my $to (@land) {
                next if $from eq $to;
                $map{$from}{skip}{$to} = 1;
            }
        }

        $map{$river}{town} = 1;
        last;
    }

    my $founded = 0;

    $founded += detect_towns_from $faction, $_ for @hexes;

    die "Can't found a town by connecting @hexes\n" if !$founded;

    $game{events}->faction_event($faction, 'mermaid:connect', 1);
}

sub command_advance {
    my ($faction, $type) = @_;

    $game{acting}->require_subaction($faction, 'advance', {});

    my $track = $faction->{$type};
    advance_track $faction, $type, $track, 0;

    $game{events}->faction_event($faction, "advance:$type", 1);
}

sub command_finish {
    $game{finished} = 1;
    score_final;
    score_final_resources;
    for my $faction ($game{acting}->factions_in_order()) {
        $faction->{passed} = 0;
    }
    $game{acting}->replace_all_actions({ type => 'gameover' });
}

sub command_income {
    my ($faction, $type) = @_;
    if ($faction) {
        my $mask;
        if (!defined $type or $type eq 'all') {
            $mask = 15;
        } elsif ($type eq 'cult') {
            $mask = 1;
        } else {
            $mask = 14;
        }
        take_income_for_faction $faction, $mask;
    } else {
        my @order = $game{acting}->factions_in_turn_order();
        if (!$game{ledger}->trailing_comment()) {
            $game{ledger}->add_comment(sprintf "Round %d income", $game{round} + 1);
        }
        for (@order) {
            if ($type) {
                handle_row_internal $_->{name}, "${type}_income_for_faction";
            } else {
                handle_row_internal $_->{name}, "income_for_faction";
            }
        }
    }
}

sub mt_shuffle {
    my ($rand, @data) = @_;

    map {
        $_->[0]
    } sort {
        $a->[1] <=> $b->[1] or $a->[0] cmp $b->[0]
    } map {
        [ $_, $rand->rand() ]
    } @data; 
}

sub check_player_count {
    return if !defined $game{player_count};

    if ($game{acting}->player_count() > $game{player_count}) {
        die "Too many players (wanted $game{player_count})\n"
    }

    for my $player (@{$game{acting}->players()}) {
        if (!$player->{username}) {
            die "The players must be specified by usernames in public games (player $player->{name} isn't)\n"
        }
    }
}

sub add_final_scoring {
    my ($scoring) = @_;

    if ($final_scoring{$scoring}) {
        $game{final_scoring}{$scoring} = $final_scoring{$scoring};
        $game{non_standard} = 1;
    } else {
        die "Unknown final scoring type: $scoring\n";
    }
    $game{ledger}->add_comment("Added final scoring tile: $scoring");
    $game{events}->global_event("scoring-$scoring", 1);
}

sub add_faction_variant {
    my ($variant) = @_;
    die "Invalid faction variant $variant\n" if !$faction_setups_extra{$variant};

    push @{$game{faction_variants}}, $variant;
}

sub command_randomize {
    my ($seed, $version) = @_;

    if (!$game{acting}->correct_player_count()) {
        return;
    }

    my $rand = Math::Random::MT->new(unpack "l6", sha1 $seed);

    my @score_tiles = sort { natural_cmp $a, $b } keys %{$game{score_pool}};
    my @score = ();
    do {
        @score = mt_shuffle $rand, @score_tiles;
    } until $score[4] ne "SCORE1" and $score[5] ne "SCORE1";
    handle_row_internal "", "score ".(join ",", @score[0..5]);

    my @bon = mt_shuffle $rand, sort grep {
        /^BON/
    } keys %{$game{pool}};
    
    while (@bon != $game{acting}->player_count() + 3) {
        handle_row_internal "", "delete ".(shift @bon);
    }

    my @players;
    if ($game{options}{'maintain-player-order'}) {
        @players = sort {
            $a->{index} <=> $b->{index}
        } @{$game{acting}->players()};
    } else {
        @players = mt_shuffle $rand, sort {
            lc $a->{name} cmp lc $b->{name} or $a->{index} <=> $b->{index}
        } @{$game{acting}->players()};
    }

    my $i = 1;
    for (@players) {
        $game{ledger}->add_comment(
            "Player $i: ".($_->{displayname} // $_->{name}));
        ++$i;
    }

    if ($game{options}{'fire-and-ice-final-scoring'}) {
        my @scoring_types = grep {
            $final_scoring{$_}->{option} and
            $final_scoring{$_}->{option} eq 'fire-and-ice-final-scoring'
        } sort { $a cmp $b } keys %final_scoring;
        if ($version ne 'v1') {
            @scoring_types = mt_shuffle $rand, @scoring_types;
        }
        my $scoring = shift @scoring_types;
        add_final_scoring $scoring;
    }

    $game{acting}->players([@players]);
}

sub command_start_planning {
    my ($faction, $from_ui) = @_;
    
    $game{planning} = 1;
    $faction->{planning} = 1;
    if ($faction->{passed}) {
        if ($game{round} == 6) {
            return;
        }
        $game{ledger}->finish_row();
        if ($faction->{income_taken} == 1) {
            if ($faction->{SPADE}) {
                if ($from_ui) {
                    $game{ledger}->finish_row();
                    $game{ledger}->start_new_row($faction);
                    return;
                } else {
                    die "Must spend spades received from cult before next move.\n"
                }
            }
            command_income undef, 'other';
        } elsif ($faction->{income_taken} == 0) {
            command_income undef, 'cult';
            if ($faction->{SPADE} or
                $faction->{UNLOCK_TERRAIN}) {
                $game{ledger}->finish_row();
                $game{ledger}->start_new_row($faction);
                return;
            }

            command_income undef, 'other';
        }

        if ($faction->{SPADE} or
            $faction->{UNLOCK_TERRAIN}) {
            return;
        }
        command_start;
    }

    $game{ledger}->finish_row();
    $game{ledger}->start_new_row($faction);
    $game{acting}->start_full_move($faction);
}

sub leech_decisions_required {
    my $faction = shift;

    return grep {
        $_->{type} eq 'leech' and $_->{faction} eq $faction->{name}
    } $game{acting}->action_required_elements();
}

sub non_leech_action_required {
    return scalar grep { $_->{type} ne 'leech' } $game{acting}->action_required_elements();
}

sub full_action_required {
    return scalar grep { $_->{type} eq 'full' } $game{acting}->action_required_elements()
}

sub finalize_setup {
    maybe_setup_pool;

    for my $type (qw(ice volcano variable variable_v2 variable_v3 variable_v4 variable_v5)) {
        if ($game{options}{"fire-and-ice-factions/$type"}) {
            add_faction_variant "final_$type";
        }
    }
}

sub preview_warn {
    if ($game{in_preview}) {
        push @{$game{preview_warnings}}, @_;
    }
}

sub command {
    my ($faction_name, $command) = @_;

    my $faction = $faction_name ? $game{acting}->get_faction($faction_name) : undef;
    my $ledger = $game{ledger};

    my $assert_faction = sub {
        die "Need faction for command $command\n" if !$faction;
        $faction;
    };

    my $assert_active_faction = sub {
        $assert_faction->();
        if ($faction->{planning} && $faction->{passed}) {
            die "Must make decisions on cult income first\n";
        }
        if (!$game{acting}->is_active($faction) and
            $game{round} > 0 and
            !$game{finished}) {
            die "Command invalid when not active player\n"
        }
        $faction;
    };

    if ($faction) {
        $faction->{waiting} = 0;
    }

    if ($command =~ /^([+-])(\d*)(\w+)(?: for ([\w -]+))?$/i) {
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));        
        my $delta = $sign * $count;
        my $type = uc ($3 // '');
        my $source = lc ($4 // '');

        if (!$game{round} and $type =~ /BON/) {
            handle_row_internal $faction_name, "pass $type";
            return 0;
        }

        command_adjust_resources $assert_faction->(), $delta, $type, $source;
    } elsif ($command =~ /^build (\w+)$/i) {
        if (!@{$game{acting}->players()}) {
            $game{acting}->advance_state('initial-dwellings');
        }
        command_build $assert_active_faction->(), uc $1;
    } elsif ($command =~ /^upgrade (\w+) to ([\w ]+)$/i) {
        die "Can't upgrade in setup phase\n" if !$game{round};
        command_upgrade $assert_active_faction->(), uc $1, alias_building uc $2;
    } elsif ($command =~ /^send (p|priest) to (\w+)(?: for (\d+))?$/i) {
        command_send $assert_active_faction->(), uc $2, $3;
    } elsif ($command =~ /^convert (\d+)?\s*(\w+) to (\d+)?\s*(\w+)$/i) {
        my $from_count = $1 || 1;
        my $from_type = alias_resource uc $2;
        my $to_count = $3 || 1;
        my $to_type = alias_resource uc $4;

        command_convert($assert_active_faction->(),
                        $from_count, $from_type,
                        $to_count, $to_type);
    } elsif ($command =~ /^gain (\w+) for (\w+)$/i) {
        my $to_type = alias_resource uc $1;
        my $from_type = alias_resource uc $2;

        command_gain($assert_faction->(), $to_type, $from_type);
    } elsif ($command =~ /^burn (\d+)$/i) {
        $assert_active_faction->();
        adjust_resource $faction, 'P2', -2*$1;
        adjust_resource $faction, 'P3', $1;
        $game{events}->faction_event($faction, "burn", $1);
    } elsif ($command =~ /^leech (\d+)(?: from (\w+))?$/i) {
        command_leech $assert_faction->(), $1, lc($2 // '');
        $ledger->force_finish_row(1);
    } elsif ($command =~ /^decline(?: (\d+) from (\w+))?$/i) { 
        command_decline $assert_faction->(), $1, lc($2 // '');
        $ledger->force_finish_row(1);
    } elsif ($command =~ /^transform (\w+)(?: to (\w+))?$/i) {
        command_transform $assert_faction->(), uc $1, lc ($2 // '');
    } elsif ($command =~ /^dig (\d+)/i) {
        command_dig $assert_active_faction->(), $1;
    } elsif ($command =~ /^bridge (\w+):(\w+)( allow_illegal)?$/i) {
        command_bridge $assert_active_faction->(), uc $1, uc $2, $3;
    } elsif ($command =~ /^connect (\w+):(\w+)(?::(\w+))?$/i) {
        command_connect $assert_active_faction->(), uc $1, uc $2, uc($3 // '');
    } elsif ($command =~ /^connect (r\d+)?$/i) {
        my $river = lc $1;
        my @neighbors = keys %{$map{$river}{adjacent}};
        command_connect $assert_active_faction->(), @neighbors;
    } elsif ($command =~ /^pass(?: (bon\d+))?$/i) {
        command_pass $assert_active_faction->(), uc ($1 // '');
        $ledger->force_finish_row(1);
    } elsif ($command =~ /^action (\w+)$/i) {
        command_action $assert_active_faction->(), uc $1;
    } elsif ($command =~ /^start$/i) {
        return 0 if full_action_required;
        command_start;
    } elsif ($command =~ /^setup (\w+)(?: for (\S+?))?(?: email (\S+))?$/i) {
        $game{ledger}->finish_row();
        die "$faction_name can't select another faction\n" if $faction_name;

        my $selected_faction = lc $1;
        finalize_setup;
        $game{acting}->advance_state('select-factions');
        setup_faction \%game, $selected_faction, $2, $3;
        $game{events}->global_event("faction-count", 1);

        my $faction = $game{acting}->get_faction($selected_faction);
        $ledger->start_new_row($faction);
        $game{ledger}->add_command("setup");
        $ledger->finish_row();

        $game{events}->faction_event($faction, "vp", $faction->{VP});
    } elsif ($command =~ /delete (\w+)$/i) {
        my $name = uc $1;

        finalize_setup;
        my $x = ($faction ? $faction : $game{pool});

        $game{ledger}->add_comment("Removing tile $name");
        if (!defined $x->{$name} or
            $name eq 'TELEPORT_TO' or
            $x->{$name} <= 1) {
            delete $x->{$name};
        } else {
            $x->{$name}--;
        }
    } elsif ($command =~ /^income$/i) {
        return 0 if non_leech_action_required;
        for my $faction ($game{acting}->factions_in_order()) {
            command_income $faction if !$faction->{income_taken};
        }
    } elsif ($command =~ /^(?:(cult|all|other)_)?income_for_faction$/i) {
        my $type = $1 // 'all';
        command_income $assert_faction->(), $type;
    } elsif ($command =~ /^advance (ship|dig)/i) {
        command_advance $assert_faction->(), lc $1;
    } elsif ($command =~ /^score (.*)/i) {
        die "$faction_name can't trigger a scoring\n" if $faction_name;

        my $setup = uc $1;
        my @score_tiles = split /,/, $setup;
        die "Invalid scoring tile setup: $setup\n" if @score_tiles != 6;
        for my $i (0..$#score_tiles) {
            my $r = $i + 1;
            my $desc = $tiles{$score_tiles[$i]}{vp_display};
            $game{ledger}->add_comment("Round $r scoring: $score_tiles[$i], $desc");
        }
        $game{score_tiles} = \@score_tiles;
    } elsif ($command =~ /^finish$/i) {
        die "Game can only be finished from admin view\n" if $faction_name;
        return 0 if non_leech_action_required;
        command_finish;
    } elsif ($command =~ /^abort$/i) {
        die "Game can only be aborted from admin view\n" if $faction_name;
        # backwards-compatibility nop
    } elsif ($command =~ /^score_resources$/i) {
        score_final_resources_for_faction $faction;
    } elsif ($command =~ /^admin email (.*)/i) {
        # backwards-compatibility nop
    } elsif ($command =~ /^dropoption (\S+)$/i) {
        delete $game{options}{$1};
    } elsif ($command =~ /^option (\S+)$/i) {
        die "$faction_name can't alter game options\n" if $faction_name;

        my $opt = lc $1;
        my %valid_options = map { ($_, 1) } qw(
            errata-cultist-power
            mini-expansion-1
            shipping-bonus
            temple-scoring-tile
            fire-and-ice-final-scoring
            fire-and-ice-factions
            fire-and-ice-factions/ice
            fire-and-ice-factions/variable
            fire-and-ice-factions/variable_v2
            fire-and-ice-factions/variable_v3
            fire-and-ice-factions/variable_v4
            fire-and-ice-factions/variable_v5
            fire-and-ice-factions/volcano
            email-notify
            loose-adjust-resource
            loose-cultist-ordering
            loose-dig
            loose-engineer-bridge
            loose-lose-cult
            loose-multi-spade
            loose-bridge-adjacency 
            loose-done
            maintain-player-order
            manual-fav5
            shapeshifter-fix-playtest-v1
            strict-leech
            strict-chaosmagician-sh
            strict-darkling-sh
            variable-turn-order);
        if (!$valid_options{$opt}) {
            die "Unknown option $opt\n";
        }
        if ($opt eq 'maintain-player-order') {
            my $wanted_count = $game{player_count};
            die "maintain-player-order option can only be used for private games\n" if $wanted_count;
        }
        
        $game{events}->global_event("option-$opt", 1);
        $game{options}{$opt} = 1;
        $game{ledger}->add_comment("option $opt");
    } elsif ($command =~ /^player (\S+)(?: email (\S*))?(?: username (\S+))?$/i) {
        die "$faction->{name} can't add new players\n" if $faction;
        $game{acting}->add_player({
            name => $1,
            email => $2,
            username => $3,
        });
        check_player_count;
    } elsif ($command =~ /^order (\S+)$/i) {
        die "$faction_name can't force player order\n" if $faction_name;
        my $i = 0;
        my %usernames = map { ($_, $i++) } split /,/, lc $1;
        my @players = sort {
            $usernames{lc $a->{username}} <=> $usernames{lc $b->{username}}
        } @{$game{acting}->players()};
        $game{acting}->players([@players]);
        $game{acting}->advance_state('select-factions');
    } elsif ($command =~ /^randomize (v1|v2) seed (.*)/i) {
        my $seed = $2;
        my $version = $1;
        die "$faction_name can't randomize game state\n" if $faction_name;

        finalize_setup;
        if (!defined $game{player_count}) {
            $game{acting}->advance_state('select-factions');
        }
        command_randomize $seed, $version;
    } elsif ($command =~ /^wait$/i) {
        ($assert_faction->())->{waiting} = 1;
    } elsif ($command =~ /^done$/i) {
        my $faction = $assert_faction->();
        if ($game{options}{'loose-done'}) {
            $faction->{allowed_actions} = 0;
        } else {
            if ($faction->{allowed_actions} != 0) {
                die "$faction->{name} must take an action\n";
            }
        }
        $faction->{allowed_sub_actions} = {};
    } elsif ($command =~ /^pick-color (\w+)$/i) {
        my $faction = $assert_faction->();
        if (!$faction->{PICK_COLOR}) {
            die "$faction->{name} are not allowed to pick a color\n";
        }
        my ($wanted_color) = assert_color alias_color $1;
        for my $other ($game{acting}->factions_in_order()) {
            next if !defined $other->{color};
            if ($other->{color} eq $wanted_color or
                ($game{round} == 0 and
                 ($other->{secondary_color} // '') eq $wanted_color)) {
                die "$wanted_color is not available\n";
            }
        }
        $game{events}->faction_event($faction, "pick-color:$wanted_color", 1);
        delete $faction->{PICK_COLOR};
        my $field = ($faction->{pick_color_field} // 'secondary_color');
        my $orig = $faction->{$field};
        $faction->{$field} = $wanted_color;
        $game{ledger}->force_finish_row(1);

        if ($field eq 'color') {
            for my $hex (keys %map) {
                if ($map{$hex}{building} and
                    $map{$hex}{color} eq $orig) {
                    $map{$hex}{color} = $wanted_color;
                }
            }
            for my $bridge (@{$game{bridges}}) {
                if ($bridge->{color} eq $orig) {
                    $bridge->{color} = $wanted_color;
                }
            }
            for my $cult (@cults) {
                for my $where (1..4) {
                    my $spot = "$cult$where";
                    if ($game{cults}{$spot}{color} and
                        $game{cults}{$spot}{color} eq $orig) {
                        $game{cults}{$spot}{color} = $wanted_color;
                    }
                }
            }
        }

        if ($faction->{locked_terrain}) {
            delete $faction->{locked_terrain}{$wanted_color};
            $faction->{unlocked_terrain}{$wanted_color} = 1;
        }
    } elsif ($command =~ /^unlock-terrain ([-\w]+)$/i) {
        my $faction = $assert_faction->();
        if (!$faction->{UNLOCK_TERRAIN}) {
            die "$faction->{name} are not allowed to unlock a new terrain\n";
        }
        my ($wanted_color) = $1;
        my $special_unlock = ($wanted_color =~ /^gain-.*$/);

        if (!$special_unlock) {
            ($wanted_color) = assert_color alias_color $1;
        }

        if (!$faction->{locked_terrain} or
            !$faction->{locked_terrain}{$wanted_color}) {
            die "$faction->{name} can't unlock $wanted_color (already unlocked?)\n"
        }

        my $effect;
        if ($special_unlock) {
            $effect = $faction->{locked_terrain}{$wanted_color}{''};
        } else {
            my $color_type = color_home_status $wanted_color;
            $effect = $faction->{locked_terrain}{$wanted_color}{$color_type};
        }

        {
            my $save = $faction->{special};
            delete $faction->{special};
            gain $faction, $effect->{gain};
            pay $faction, $effect->{cost};
            $faction->{special} = $save;
        }

        $faction->{unlocked_terrain}{$wanted_color} = 1;

        if (!$effect->{permanent}) {
            delete $faction->{locked_terrain}{$wanted_color};
        }

        # XXX really ugly hack to stop unlocking from triggering
        # for riverwalkers once everything has been unlocked.
        if (0 == grep { $_ !~ $special_unlock } keys %{$faction->{locked_terrain}}) {
            delete $faction->{special}{P};
        }

        if (!--$faction->{UNLOCK_TERRAIN}) {
            $game{acting}->dismiss_action($faction, 'unlock-terrain');
        }
    } elsif ($command =~ /^start_planning$/i) {
        command_start_planning $assert_faction->(), 1;
    } elsif ($command =~ /^map (.*)/i) {
        die "$faction_name can't switch game map\n" if $faction_name;
        if ($1 eq 'original') {
            $game{map_variant} = undef;
        } else {
            $game{map_variant} = $1;
        }
        $game{ledger}->add_comment("map $1");
    } elsif ($command =~ /^faction-variant (.*)/i) {
        die "$faction_name can't set game variant\n" if $faction_name;
        add_faction_variant lc $1;
    } elsif ($command =~ /^final-scoring (.*)/i) {
        die "$faction_name can't trigger final scoring\n" if $faction_name;
        add_final_scoring $1;
    } elsif ($command =~ /^start-preview$/i) {
        die "$faction_name can't trigger preview mode\n" if $faction_name;
        
        $game{in_preview} = 1;
    } elsif ($command =~ /^drop-faction player(\d+)$/i) {
        die "Players can only be dropped from admin view\n" if $faction_name;
        my $player = $game{acting}->players()->[$1 - 1];
        die "Invalid player index: $1\n" if !$player;
        my $dummy_faction = {
            username => $player->{username},
            player => $player->{displayname},
            dropped => 1,
            income_taken => 0,
            name => "nofaction$1",
            display => 'No Faction',
            dummy => 1,
            start_order => $1,
            start_player => ($game{acting}->faction_count() ? 0 : 1),
        };
        $game{acting}->register_faction($dummy_faction);
    } elsif ($command =~ /^drop-faction (\w+)$/i) {
        my $f = lc $1;
        die "Players can only be dropped from admin view\n" if $faction_name and $faction_name ne $f;

        my $faction = $game{acting}->get_faction($f);
        die "Faction $f is not in the game" if !$faction;
        $faction->{dropped} = 1;
        $faction->{allowed_actions} = 0;
        $faction->{allowed_sub_actions} = {};

        $game{events}->faction_event($faction, "drop", 1);
        $game{events}->global_event("drop-faction", 1);

        $game{acting}->dismiss_action($faction, undef);

        my $discard = find_bonus_to_discard $faction;
        if ($discard) {
            adjust_resource $faction, $discard, -1;
        }
        $game{acting}->setup_order(
            [ grep { $_->[0] ne $f } @{$game{acting}->setup_order()} ]
            );

        $game{acting}->maybe_advance_to_next_player($faction);
        $game{ledger}->add_comment("$f dropped from the game");
    } else {
        die "Could not parse command '$command'.\n";
    }

    1;
}

sub do_command {
    my $ledger = $game{ledger};
    my ($faction_name, @commands) = @_;
    
    return if !@commands;
    die if @commands > 1;

    if ($faction_name eq 'comment') {
        $game{ledger}->add_comment("@commands");
        return;
    }

    my $faction;
    
    if ($faction_name ne '') {
        $faction = $game{acting}->get_faction($faction_name);
        if (!$faction) {
            my $faction_list = join ", ", map { $_->{name} } $game{acting}->factions_in_order();
            die "Unknown faction: '$faction->{name}' (expected one of $faction_list)\n";
        }
    }

    if ($faction and
        (!$ledger->collecting_row() or
         $faction_name ne $ledger->current_faction()->{name})) {
        $ledger->start_new_row($faction);
    }

    command $faction_name, $commands[0];
    if ($faction && !$faction->{dropped}) {
        $game{ledger}->add_command($commands[0]);
    }

    if ($game{ledger}->force_finish_row()) {
        $game{acting}->maybe_advance_to_next_player($faction);
        $game{ledger}->finish_row();
    }
}

sub clean_commands {
    local $_ = shift;
    my $prefix = '';
    my @comments = ();

    # Remove comments
    if (s/#(.*)//) {
        if ($1 ne '') {
            my $comment = $1;
            $comment =~ s/email \S*@\S*/email ***/g;
            # Interpret ## as a pragma rather than a commit
            if ($comment !~ /^#/) {
                push @comments, ['comment', $comment ];
            }
        }
    }

    # Clean up whitespace
    s/\s+/ /g;
    s/^\s+//;
    s/\s+$//;

    s/dragonmasters/dragonlords/gi;

    # Parse the prefix
    if (s/^(.*?)://) {
        $prefix = lc $1;
    }

    # Quick backwards compatibility hacks
    if ($prefix eq 'engineers') {
        s/-2w\.\s*bridge/convert 2w to bridge. bridge/i;
        s/convert 2 *w to 1?bridge/action ACTE/gi;
    }
    s/\s*pass\.\s*\+bon/pass bon/i;
    s/^\s*\+bon/pass BON/i;
    s/(build \w+)\. (transform \w+(?: to \w+)?)/$2. $1/i;
    s/\s*(pass \w+)\. (convert (\d+ *)?\w+ to (\d+ *)?\w+)/$2. $1/i;
    s/(dig \w). (action \w+)/$2. $1/i;

    my @commands = $_;
    if ($prefix) {
        # Split subcommands
        @commands = split /[.]/, $_;
    }

    # Clean them up
    for (@commands) {
        s/^\s+//;
        s/\s+$//;
        s/(\W)\s(\w)/$1$2/g;
        s/(\w)\s(\W)/$1$2/g;
    }

    @commands = ((grep { /^(leech|decline)/i } @commands),
                 (grep { !/^(leech|decline)/i } @commands));

    return @comments, map { [ $prefix, $_ ] } grep { /\S/ } @commands;
}

sub rewrite_stream {
    my @command_stream = @_;

    for (my $i = 0; $i < @command_stream; ++$i) {
        my $this = $command_stream[$i];
        my $next = $command_stream[$i+1] // ['', ''];

        # If you have two manipulations of the same resource after one
        # another, merge. (Needed for Auren SH validation).
        if (($this->[0] eq $next->[0]) and
            ($this->[1] =~ /^\+(\d*)(\w+)/ and
             lc $this->[1] eq lc $next->[1])) {
            $this->[1] = "+".(($1 || 1) * 2)."$2";
            $next->[1] = '';
        }

        if (!$this->[0] and $this->[1] =~ /^player-count (\d+)$/i) {
            $game{player_count} = 1*$1;
            $this->[1] = '';
        }

        if ($this->[0] and $this->[1] =~ /^\s*resign\s*$/i) {
            $this->[1] = "drop-faction $this->[0]";
        }

        if (($this->[0] and $next->[0] and $this->[0] eq $next->[0]) and
            $this->[1] =~ /^convert 2W to 1?BRIDGE$/i and
            $next->[1] =~ /^-BRIDGE$/i) {
            $this->[1] = '';
            $next->[1] = '';
        }
    }

    grep { $_->[1] } @command_stream;
}

sub handle_row_internal {
    do_command @_;
    $game{ledger}->finish_row();
}

sub play {
    my ($commands, $max_row) = @_;

    for (my $i = 0; $i < @{$commands}; ++$i) {
        my $this = $commands->[$i];
        my $next = $commands->[$i+1];
        eval {
            do_command $this->[0], $this->[1];
        }; if ($@) {
            die "Error in command '".($this->[1])."': $@";
        }

        my $active_faction = $game{acting}->active_faction();
        if (!defined $next and $active_faction) {
            $active_faction->{allowed_sub_actions}{burn} = 1;
            $active_faction->{allowed_sub_actions}{convert} = 1;
        }

        my $faction = $game{acting}->get_faction($this->[0]);
        if (($next->[0] // '') ne ($this->[0] // '')) {
            if ($this->[0] and $faction) {
                $game{acting}->maybe_advance_to_next_player($faction);
            }
        }
        $game{acting}->what_next();

        if ($faction and $faction->{passed} and $faction->{planning}
            and !($faction->{SPADE} or $faction->{UNLOCK_TERRAIN})) {
            command_start_planning($faction);
        }

        if ($max_row) {
            my $size = $game{ledger}->size();
            if ($size >= ($max_row-1)) {
                return $size;
            }
        }

        if ($game{finished}) {
           return 0;
        }
    }

    return 0;
}

1;
