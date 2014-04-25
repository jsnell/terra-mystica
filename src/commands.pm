package terra_mystica;

use strict;

use Digest::SHA1 qw(sha1);
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
            # die "Advancing $delta steps on $type cult not allowed\n";
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
            }
        } elsif ($faction->{CULT} > $delta) {
            die "All cult advances must be used on the same cult track\n";
        } else {
            $faction->{CULT} -= $delta;
            $checked = 1;
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
        $checked = 1;
    }

    if (!$checked) {
        $ledger->warn("dodgy resource manipulation ($delta $type)");
    }

    adjust_resource $faction, $type, $delta, $source;

    # Small hack: always remove the notifier for a cultist special cult
    # increase. Needs to be done like this, since we don't want + / - to
    # count as full actions.
    $game{acting}->dismiss_action($faction, 'cult');

    # Handle throwing away spades with "-SPADE", e.g. if you are playing
    # Giants.
    if ($type eq 'SPADE' and $faction->{SPADE} < 1) {
        $game{acting}->dismiss_action($faction, 'transform');
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

    my $tf_needed = $map{$where}{color} ne $color;

    if (!$tf_needed and
        keys %{$faction->{allowed_build_locations}} and
        !$faction->{allowed_build_locations}{$where}) {
        delete $faction->{allowed_sub_actions}{build};
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

    maybe_score_favor_tile $faction, $type;
    maybe_score_current_score_tile $faction, $type, 'build';

    $map{$where}{building} = $type;
    push @{$faction->{locations}}, $where;

    detect_towns_from $faction, $where;
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
            last;
        }
    }

    if ($amount) {
        die "No $amount spot on $cult track\n" if $gain->{$cult} != $amount;
    }

    $gain->{$cult} += ($faction->{PRIEST_CULT_BONUS} // 0);

    gain $faction, $gain;

    adjust_resource $faction, "P", -1;
}

sub command_convert {
    my ($faction,
        $from_count, $from_type,
        $to_count, $to_type) = @_;

    my %exchange_rates = ();

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

sub command_leech {
    my ($faction, $pw, $from) = @_;
    my $faction_name = $faction->{name};
    my $ledger = $game{ledger};

    my $actual_pw = gain_power $faction, $pw;
    my $vp = $actual_pw - 1;

    my $found_leech_record = 0;
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
        if ($_->{from_faction} eq 'cultists' and
            $_->{actual} > 0 and
            !$from_faction->{leech_cult_gained}{$_->{leech_id}}++) {
            $from_faction->{CULT}++;
            $game{acting}->require_action($from_faction,
                                          { type => 'cult',
                                            amount => 1 });
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

    if ($found_leech_record) {
        $game{acting}->clear_empty_actions();
    } else {
        if (!$from and !$game{options}{'strict-leech'}) {
            $ledger->warn("invalid leech $pw (accepting anyway)");
        } else {
            die "invalid leech $pw from $from\n";
        }
    }

    if ($actual_pw > 0) {
	adjust_resource $faction, 'VP', -$vp, 'leech';
    }

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
}

sub command_decline {
    my ($faction, $amount, $from) = @_;

    if (!$amount) {
        # Decline all
        my @declines = grep {
            $_->{faction} eq $faction->{name} and $_->{type} eq 'leech';
        } @{$game{acting}->action_required()};
        for (@declines) {
            command_decline($faction, $_->{amount}, $_->{from_faction});
        }
    } else {
        my $declined = 0;
        for (@{$game{acting}->action_required()}) {
            if ($_->{faction} eq $faction->{name} and
                $_->{type} eq 'leech' and
                $_->{amount} eq $amount and
                $_->{from_faction} eq $from) {
                my $from_faction = $game{acting}->get_faction($_->{from_faction});
                my $leech_id = $_->{leech_id};
                $from_faction->{leech_rejected}{$leech_id}++;
                cultist_maybe_gain_power($_);
                $_ = '';
                $declined = 1;
                last;
            }
        }
        $game{acting}->clear_empty_actions();
        die "Invalid decline ($amount from $from)\n" if !$declined;
    }
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
    # Of course all of this only matters for the cultists.
    return if $record->{from_faction} ne 'cultists';
    # And when playing with the new rule.
    return if !$game{options}{'errata-cultist-power'};

    my @data_fields = qw(VP C W P P1 P2 P3 PW FIRE WATER EARTH AIR CULT);

    my %old_data = map { $_, $faction->{$_} } @data_fields;
    gain_power $faction, 1;
    my %new_data = map { $_, $faction->{$_} } @data_fields;
    my %pretty_delta = pretty_resource_delta(\%old_data, \%new_data);

    $game{ledger}->add_row({
        faction => $faction->{name},
        commands => "[+1pw, all opponents declined power]",
        map { $_, $pretty_delta{$_} } @data_fields
    });
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

    if ($color_difference and !$faction->{passed}) {
        $game{acting}->require_subaction($faction, 'transform', {
            transform => ($faction->{allowed_sub_actions}{transform} // 1) - 1,
            build => $faction->{allowed_sub_actions}{build} // 0,
        });
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

    if (!$faction->{SPADE}) {
        $game{acting}->dismiss_action($faction, 'transform');
        delete $faction->{allowed_sub_actions}{transform};
    }

    if ($color eq $faction->{color}) {
        $faction->{allowed_build_locations}{$where} = 1;
    }

    $map{$where}{color} = $color;

    detect_towns_from $faction, $where;
}

sub command_dig {
    my ($faction, $amount) = @_;

    my $cost = $faction->{dig}{cost}[$faction->{dig}{level}];
    my $gain = $faction->{dig}{gain}[$faction->{dig}{level}];

    if (!$faction->{allowed_sub_actions}{transform}) {
        $game{acting}->require_subaction($faction, 'dig', {
            transform => 1,
            build => 1
        });
    };

    if (!$gain) {
        adjust_resource $faction, 'SPADE', $amount;
    }
    pay $faction, $cost for 1..$amount;
    gain $faction, $gain, 'faction' for 1..$amount;
}

sub command_bridge {        
    my ($faction, $from, $to, $allow_illegal) = @_;

    $game{acting}->require_subaction($faction, 'bridge', {});

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

    if (!$faction->{BRIDGE}) {
        die "Can't build bridge\n";
    }
    delete $faction->{BRIDGE};

    push @{$game{bridges}}, {from => $from, to => $to, color => $faction->{color}};

    detect_towns_from $faction, $from;
    detect_towns_from $faction, $to;
}

sub command_pass {
    my ($faction, $bon) = @_;
    my $faction_name = $faction->{name};
    my $ledger = $game{ledger};

    my $discard;

    $game{acting}->require_subaction($faction, 'pass', {});

    my $passed_count = grep { $_->{passed} } $game{acting}->factions_in_order();

    my $first_to_pass = $passed_count == 0;

    if ($game{round} and $first_to_pass) {
        $_->{start_player} = 0 for $game{acting}->factions_in_order();
        $faction->{start_player} = 1;
    }

    if ($game{options}{'strict-chaosmagician-sh'} and $faction->{passed}) {
        die "Can't pass multiple times in one round\n";
    }

    $faction->{passed} = 1;
    for (keys %{$faction}) {
        next if !$faction->{$_};

        if (/^BON/) {
            $discard = $_;
        }
    }

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
        }
    } elsif ($game{round} != 6) {
        die "Must take a bonus tile when passing (except on last round)\n"
    }

    if ($discard) {
        adjust_resource $faction, $discard, -1;
    }
}

sub command_action {
    my ($faction, $action) = @_;
    my $faction_name = $faction->{name};

    if ($action !~ /^ACT[1-6]/ and !$faction->{$action}) {
        die "No $action space available\n"
    }    
    my $name = $action;
    if (!exists $actions{$name}) {
        die "Unknown action $name\n";
    }

    if ($action !~ /^ACT/) {
        $action .= "/$faction_name";
    }

    if ($map{$action}{blocked} && !
        $faction->{allow_reuse}{$action}) {
        die "Action space $action is blocked\n"
    }

    my %subaction = exists $actions{$name}{subaction} ?
        %{$actions{$name}{subaction}} :
        ();

    $game{acting}->require_subaction($faction, 'action', \%subaction);

    pay $faction, $actions{$name}{cost}, ($faction->{discount} and $faction->{discount}{$name});
    gain $faction, $actions{$name}{gain};

    $map{$action}{blocked} = 1;
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
    }

    my $start_player = $order[0];
    $game{acting}->require_action($start_player,
                                  { type => 'full' });
    $game{acting}->start_full_move($start_player);
    $game{acting}->full_turn_played(0);
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
}

sub command_advance {
    my ($faction, $type) = @_;

    $game{acting}->require_subaction($faction, 'advance', {});

    my $track = $faction->{$type};
    advance_track $faction, $type, $track, 0;
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
    my $faction = shift;
    if ($faction) {
        take_income_for_faction $faction;
    } else {
        my @order = $game{acting}->factions_in_turn_order();
        if (!$game{ledger}->trailing_comment()) {
            $game{ledger}->add_comment(sprintf "Round %d income", $game{round} + 1);
        }
        for (@order) {
            handle_row_internal $_->{name}, "income_for_faction";
        }
    }
}

sub mt_shuffle {
    my ($rand, @data) = @_;

    map {
        $_->[0]
    } sort {
        $a->[1] <=> $b->[1]
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

sub command_randomize_v1 {
    if (!$game{acting}->correct_player_count()) {
        return;
    }

    my $seed = shift;
    my $rand = Math::Random::MT->new(unpack "l6", sha1 $seed);

    my @score = ();
    do {
        @score = mt_shuffle $rand, map { "Score$_" } 1..8;
    } until $score[4] ne "Score1" and $score[5] ne "Score1";
    handle_row_internal "", "score ".(join ",", @score[0..5]);

    my @bon = mt_shuffle $rand, sort grep {
        /^BON/
    } keys %{$game{pool}};
    
    while (@bon != $game{acting}->player_count() + 3) {
        handle_row_internal "", "delete ".(shift @bon);
    }

    my @players = mt_shuffle $rand, sort {
        lc $a->{name} cmp lc $b->{name} or $a->{index} <=> $b->{index}
    } @{$game{acting}->players()};

    my $i = 1;
    for (@players) {
        $game{ledger}->add_comment(
            "Player $i: ".($_->{displayname} // $_->{name}));
        ++$i;
    }

    $game{acting}->players([@players]);
}

sub command_start_planning {
    my $faction = shift;

    $faction->{planning} = 1;
    if ($faction->{passed}) {
        command_income;
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
        die "Command invalid when not active player\n" if
            !$game{acting}->is_active($faction) and
            $game{round} > 0 and
            !$game{finished};
        $faction;
    };

    if ($faction) {
        $faction->{waiting} = 0;
    }

    if ($command =~ /^([+-])(\d*)(\w+)(?: for ([\w -]+))?$/i) {
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));        
        my $delta = $sign * $count;
        my $type = uc $3;

        if (!$game{round} and $type =~ /BON/) {
            handle_row_internal $faction_name, "pass $type";
            return 0;
        }

        command_adjust_resources $assert_faction->(), $delta, $type, lc $4;
    } elsif ($command =~ /^build (\w+)$/i) {
        $game{acting}->advance_state('initial-dwellings');
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
    } elsif ($command =~ /^burn (\d+)$/i) {
        $assert_active_faction->();
        adjust_resource $faction, 'P2', -2*$1;
        adjust_resource $faction, 'P3', $1;
    } elsif ($command =~ /^leech (\d+)(?: from (\w+))?$/i) {
        command_leech $assert_faction->(), $1, lc $2;
        $ledger->force_finish_row(1);
    } elsif ($command =~ /^decline(?: (\d+) from (\w+))?$/i) { 
        command_decline $assert_faction->(), $1, lc $2;
        $ledger->force_finish_row(1);
    } elsif ($command =~ /^transform (\w+)(?: to (\w+))?$/i) {
        command_transform $assert_faction->(), uc $1, lc ($2 // '');
    } elsif ($command =~ /^dig (\d+)/i) {
        command_dig $assert_active_faction->(), $1;
    } elsif ($command =~ /^bridge (\w+):(\w+)( allow_illegal)?$/i) {
        command_bridge $assert_active_faction->(), uc $1, uc $2, $3;
    } elsif ($command =~ /^connect (\w+):(\w+)(?::(\w+))?$/i) {
        command_connect $assert_active_faction->(), uc $1, uc $2, uc $3;
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
        maybe_setup_pool;
        $game{acting}->advance_state('select-factions');
        setup_faction \%game, lc $1, $2, $3;
    } elsif ($command =~ /delete (\w+)$/i) {
        my $name = uc $1;

        maybe_setup_pool;
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
    } elsif ($command =~ /^income_for_faction$/i) {
        command_income $assert_faction->();
    } elsif ($command =~ /^advance (ship|dig)/i) {
        command_advance $assert_faction->(), lc $1;
    } elsif ($command =~ /^score (.*)/i) {
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
    } elsif ($command =~ /^option (\S+)$/i) {
        my $opt = lc $1;
        my %valid_options = map { ($_, 1) } qw(
            errata-cultist-power
            mini-expansion-1
            shipping-bonus
            email-notify
            strict-leech
            strict-chaosmagician-sh
            strict-darkling-sh);
        if (!$valid_options{$opt}) {
            die "Unknown option $opt\n";
        }
        $game{options}{$opt} = 1;
        $game{ledger}->add_comment("option $opt");
    } elsif ($command =~ /^player (\S+)(?: email (\S*))?(?: username (\S+))?$/i) {
        $game{acting}->add_player({
            name => $1,
            email => $2,
            username => $3,
        });
        check_player_count;
    } elsif ($command =~ /^order ([\w,]+)$/i) {
        my $i = 0;
        my %usernames = map { ($_, $i++) } split /,/, lc $1;
        my @players = sort {
            $usernames{lc $a->{username}} <=> $usernames{lc $b->{username}}
        } @{$game{acting}->players()};
        $game{acting}->players([@players]);
        $game{acting}->advance_state('select-factions');
    } elsif ($command =~ /^randomize v1 seed (.*)/i) {
        maybe_setup_pool;
        if (!defined $game{player_count}) {
            $game{acting}->advance_state('select-factions');
        }
        command_randomize_v1 $1;
    } elsif ($command =~ /^wait$/i) {
        ($assert_faction->())->{waiting} = 1;
    } elsif ($command =~ /^done$/i) {
        ($assert_faction->())->{allowed_sub_actions} = {};
        ($assert_faction->())->{allowed_actions} = 0;
    } elsif ($command =~ /^pick-color (\w+)$/i) {
        my $faction = $assert_faction->();
        if (!$faction->{PICK_COLOR}) {
            die "$faction->{name} is not allowed to pick a color\n";
        }
        my ($wanted_color) = assert_color alias_color $1;
        for my $other ($game{acting}->factions_in_order()) {
            if ($other->{color} eq $wanted_color or
                ($other->{secondary_color} // '') eq $wanted_color) {
                die "$wanted_color is not available\n";
            }
        }
        delete $faction->{PICK_COLOR};
        $faction->{secondary_color} = $wanted_color;
    } elsif ($command =~ /^start_planning$/i) {
        command_start_planning $assert_faction->();
    } elsif ($command =~ /^map (.*)/i) {
        if ($1 eq 'original') {
            $game{map_variant} = undef;
        } else {
            $game{map_variant} = $1;
        }
    } elsif ($command =~ /^faction-variant (.*)/i) {
        push @{$game{faction_variants}}, $1;
        $game{faction_variant_help} = "/playtestfactions/";
    } elsif ($command =~ /^final-scoring (.*)/i) {
        if ($final_scoring{$1}) {
            $game{final_scoring}{$1} = $final_scoring{$1};
            $game{final_scoring_help} = "/playtestscoring/";
            $game{non_standard} = 1;
        } else {
            die "Unknown final scoring type: $1\n";
        }
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
    if ($faction) {
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

    # Parse the prefix
    if (s/^(.*?)://) {
        $prefix = lc $1;
    }

    # Quick backwards compatibility hacks
    if ($prefix eq 'engineers') {
        s/-2w\.\s*bridge/convert 2w to bridge. bridge/i;
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

    for (my $i = 0; $i < @command_stream-1; ++$i) {
        my $this = $command_stream[$i];
        my $next = $command_stream[$i+1];

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

        if ($faction and $faction->{passed} and $faction->{planning}) {
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
