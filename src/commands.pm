package terra_mystica;

use strict;

use Digest::SHA1 qw(sha1);
use Math::Random::MT;

use buildings;
use cults;
use factions;
use map;
use income;
use ledger;
use resources;
use scoring;
use tiles;
use towns;

use vars qw(%state);
use vars qw($admin_email %options $active_faction $player_count);

sub handle_row;
sub handle_row_internal;

sub allow_full_move {
    my $faction = shift;
    $active_faction = $faction->{name};
    $faction->{allowed_actions} = 1;
    $faction->{allowed_sub_actions} = {};
    $faction->{allowed_build_locations} = {};
    delete $faction->{TELEPORT_TO};
}

sub require_subaction {
    my ($faction, $type, $followup) = @_;
    my $ledger = $state{ledger};

    if (($faction->{allowed_sub_actions}{$type} // 0) > 0) {
        $faction->{allowed_sub_actions}{$type}--;
        $faction->{allowed_sub_actions} = $followup if $followup;
    } elsif ($faction->{allowed_actions}) {
        $faction->{allowed_actions}--;
        $faction->{allowed_sub_actions} = $followup if $followup;
        # Taking an action is an implicit "decline"
        command_decline($faction, undef, undef);
    } else {
        my @unpassed = grep { !$_->{passed} } values %factions;
        if (@unpassed == 1 or $faction->{planning}) {
            finish_row($faction);
            $ledger->start_new_row($faction);

            allow_full_move $faction;
            require_subaction($faction, $type, $followup);
            return;
        } else {
            die "'$type' command not allowed (trying to take multiple actions in one turn?)\n"
        }
    }
}

sub allow_pass {
    my $faction = shift;
    $faction->{allowed_sub_actions} = {
        pass => 1,
    };    
}

sub allow_build {
    my $faction = shift;
    $faction->{allowed_sub_actions} = {
        build => 1,
    };
}

sub command_adjust_resources {
    my ($faction, $delta, $type, $source) = @_;
    my $faction_name = $faction->{name};
    my $ledger = $state{ledger};
    my $checked = 0;

    if (grep { $_ eq $type } @cults) {
        if ($faction->{CULT} < $delta) {
            # die "Advancing $delta steps on $type cult not allowed\n";
        } elsif ($delta < 0) {
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

    if ($type eq 'VP' and $state{finished}) {
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
    @action_required = grep {
        $_->{faction} ne $faction->{name} or $_->{type} ne 'cult'
    } @action_required;       

    # Handle throwing away spades with "-SPADE", e.g. if you are playing
    # Giants.
    if ($type eq 'SPADE' and $faction->{SPADE} < 1) {
        @action_required = grep {
            $_->{faction} ne $faction->{name} or $_->{type} ne 'transform'
        } @action_required;
    }
}

sub command_build {
    my ($faction, $where) = @_;
    my $faction_name = $faction->{name};

    my $free = ($state{round} == 0);
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

    require_subaction $faction, 'build', {
        transform => $tf_needed
    };

    if ($faction->{TELEPORT_NO_TF}) {
        $faction->{TELEPORT_NO_TF}--;
        die "Transforming terrain forbidden during this action\n"
            if $tf_needed;
    } else {
        if ($tf_needed) {
            command $faction_name, "transform $where to $color";
        } else {
            my ($cost, $gain, $teleport) = check_reachable $faction, $where;
            if ($teleport) {
                $faction->{TELEPORT_TO} = $where;
            }
            pay $faction, $cost;
            gain $faction, $gain;
        }
    }

    if ($faction->{SPADE} > 0) {
        die "Must do all transforms before building ($faction->{SPADE} spades) remaining\n";
    }

    if (!$state{round}) {
        if ($faction_name ne $setup_order[0]) {
            die "Expected $setup_order[0] to place building, not $faction_name\n"
        }
        shift @setup_order;
        check_setup_actions();
    }

    note_leech $faction, $where;

    advance_track $faction, $type, $faction->{buildings}{$type}, $free;

    maybe_score_favor_tile $faction, $type;
    maybe_score_current_score_tile $faction, $type;

    $map{$where}{building} = $type;
    push @{$faction->{locations}}, $where;

    detect_towns_from $faction, $where;
}

sub command_upgrade {
    my ($faction, $where, $type) = @_;

    require_subaction $faction, 'upgrade', {};

    die "Unknown location '$where'\n" if !$map{$where};

    my $color = $faction->{color};
    die "$where has wrong color ($color vs $map{$where}{color})\n" if
        $map{$where}{color} ne $color;

    my %wanted_oldtype = (TP => 'D', TE => 'TP', SH => 'TP', SA => 'TE');
    my $oldtype = $map{$where}{building};

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
    maybe_score_current_score_tile $faction, $type;

    $map{$where}{building} = $type;

    detect_towns_from $faction, $where;
}

sub command_send {
    my ($faction, $cult, $amount) = @_;

    require_subaction $faction, 'send', {};

    die "Unknown cult track $cult\n" if !grep { $_ eq $cult } @cults;

    my $gain = { $cult => 1 };
    for (1..4) {
        my $where = "$cult$_";
        if (!$cults{$where}{building}) {
            if ($amount) {
                next if $cults{$where}{gain}{$cult} != $amount;
            }

            $gain = $cults{$where}{gain};
            delete $cults{$where}{gain};
            $cults{$where}{building} = 'P';
            $cults{$where}{color} = $faction->{color};
            $faction->{MAX_P}--;
            last;
        }
    }

    if ($amount) {
        die "No $amount spot on $cult track\n" if $gain->{$cult} != $amount;
    }

    gain $faction, $gain;

    adjust_resource $faction, "P", -1;
}

sub command_convert {
    my ($faction,
        $from_count, $from_type,
        $to_count, $to_type) = @_;

    my %exchange_rates = ();

    # Have to leech before declining power
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
    my $ledger = $state{ledger};

    my $actual_pw = gain_power $faction, $pw;
    my $vp = $actual_pw - 1;

    my $found_leech_record = 0;
    for (@action_required) {
        next if $_->{faction} ne $faction_name;
        next if $_->{type} ne 'leech';
        
        if (($_->{amount} ne $pw and $_->{amount} ne $actual_pw) or
            ($from and $from ne $_->{from_faction})) {
            $_->{leech_tainted} =
                "leech $pw from $from";
            next;
        }

        if ($_->{from_faction} eq 'cultists' and
            $_->{actual} > 0 and
            !$factions{cultists}{leech_cult_gained}{$_->{leech_id}}++) {
            $factions{cultists}{CULT}++;
            push @action_required, { type => 'cult',
                                     amount => 1,
                                     faction => 'cultists' };
        }

        if ($_->{leech_tainted}) {
            my $err = "'leech $pw from $from' should happen before '$_->{leech_tainted}'";
            if ($options{'strict-leech'}) {
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
        @action_required = grep { $_ ne '' } @action_required;
    } else {
        if (!$from and !$options{'strict-leech'}) {
            $ledger->warn("invalid leech $pw (accepting anyway)");
        } else {
            die "invalid leech $pw from $from\n";
        }
    }

    if ($actual_pw > 0) {
	adjust_resource $faction, 'VP', -$vp, 'leech';
    }

    my $can_gain = min $faction->{P1} * 2 + $faction->{P2};
    for my $record (@action_required) {
        if ($record->{type} eq 'leech' and
            $record->{faction} eq $faction_name) {
            if (!$can_gain and $record->{actual}) {
                my $from_faction = $factions{$record->{from_faction}};
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
        } @action_required;
        for (@declines) {
            command_decline($faction, $_->{amount}, $_->{from_faction});
        }
    } else {
        my $declined = 0;
        for (@action_required) {
            if ($_->{faction} eq $faction->{name} and
                $_->{type} eq 'leech' and
                $_->{amount} eq $amount and
                $_->{from_faction} eq $from) {
                my $from_faction = $factions{$_->{from_faction}};
                my $leech_id = $_->{leech_id};
                $from_faction->{leech_rejected}{$leech_id}++;
                cultist_maybe_gain_power($_);
                $_ = '';
                $declined = 1;
                last;
            }
        }
        @action_required = grep { $_ ne '' } @action_required;
        die "Invalid decline ($amount from $from)\n" if !$declined;
    }
}

sub cultist_maybe_gain_power {
    my $record = shift;
    my $faction = $factions{$record->{from_faction}};

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
    return if !$options{'errata-cultist-power'};

    my @data_fields = qw(VP C W P P1 P2 P3 PW FIRE WATER EARTH AIR CULT);

    my %old_data = map { $_, $faction->{$_} } @data_fields;
    gain_power $faction, 1;
    my %new_data = map { $_, $faction->{$_} } @data_fields;
    my %pretty_delta = pretty_resource_delta(\%old_data, \%new_data);

    $state{ledger}->add_row({
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
        require_subaction $faction, 'transform', {
            transform => ($faction->{allowed_sub_actions}{transform} // 1) - 1,
            build => $faction->{allowed_sub_actions}{build} // 0,
        };
    }

    if ($teleport) {
        $faction->{TELEPORT_TO} = $where;
    }
    pay $faction, $transform_cost;
    gain $faction, $transform_gain;

    if (!$faction->{SPADE}) {
        @action_required = grep {
            $_->{faction} ne $faction->{name} or $_->{type} ne 'transform'
        } @action_required;       
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
        require_subaction $faction, 'dig', {
            transform => 1,
            build => 1
        };
    };

    adjust_resource $faction, 'SPADE', $amount;
    pay $faction, $cost for 1..$amount;
    gain $faction, $gain, 'faction' for 1..$amount;
}

sub command_bridge {        
    my ($faction, $from, $to, $allow_illegal) = @_;

    require_subaction $faction, 'bridge', {};

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

    push @bridges, {from => $from, to => $to, color => $faction->{color}};

    detect_towns_from $faction, $from;
    detect_towns_from $faction, $to;
}

sub command_pass {
    my ($faction, $bon) = @_;
    my $faction_name = $faction->{name};
    my $ledger = $state{ledger};

    my $discard;

    require_subaction $faction, 'pass', {};

    my $passed_count = grep { $_->{passed} } values %factions;
    my $first_to_pass = $passed_count == 0;

    if ($state{round} and $first_to_pass) {
        $_->{start_player} = 0 for values %factions;
        $faction->{start_player} = 1;
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
        if (!$state{round}) {
            if ($faction_name ne $setup_order[0]) {
                die "Expected $setup_order[0] to pick bonus, not $faction_name\n"
            }
            shift @setup_order;
        }

        if ($state{round} == 6) {
            $ledger->warn("Can't take a bonus tile when passing on last round\n");
        } else {
            adjust_resource $faction, $bon, 1;
        }
    } elsif ($state{round} != 6) {
        die "Must take a bonus tile when passing (except on last round)\n"
    }

    if ($discard) {
        adjust_resource $faction, $discard, -1;
    }

    if ($faction->{planning}) {
        finish_row($faction);
        $ledger->start_new_row($faction);
        command_start_planning($faction);
    }
}

sub command_action {
    my ($faction, $action) = @_;
    my $faction_name = $faction->{name};

    require_subaction $faction, 'action', clone $actions{$action}{subaction};

    if ($action !~ /^ACT[1-6]/ and !$faction->{$action}) {
        die "No $action space available\n"
    }
    
    my $name = $action;
    if ($action !~ /^ACT/) {
        $action .= "/$faction_name";
    }

    if ($actions{$name}) {
        pay $faction, $actions{$name}{cost};
        gain $faction, $actions{$name}{gain};
    } else {
        die "Unknown action $name\n";
    }

    if ($map{$action}{blocked}) {
        die "Action space $action is blocked\n"
    }
    $map{$action}{blocked} = 1;
}

sub command_start {
    my $ledger_state = $state{ledger};
    $state{round}++;
    $state{turn} = 1;
    $ledger_state->{printed_turn} = 0;

    for my $faction_name (@factions) {
        my $faction = $factions{$faction_name};
        die "Round $state{round} income not taken for $faction_name\n" if
            !$faction->{income_taken};
        $faction->{income_taken} = 0;
        $faction->{passed} = 0 for keys %factions;
    }

    $map{$_}{blocked} = 0 for keys %map;
    for (keys %pool) {
        next if !/^BON/;
        next if !$pool{$_};
        $bonus_coins{$_}{C}++;
    }

    $state{ledger}->turn($state{round}, $state{turn});

    my @order = factions_in_turn_order;
    my $i = 0;
    for (@order) {
        $factions{$_}{order} = $i++;
    }

    my $start_player = $order[0];
    push @action_required, { type => 'full',
                             faction => $start_player };
    allow_full_move $factions{$start_player};
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

    require_subaction $faction, 'advance', {};

    my $track = $faction->{$type};
    advance_track $faction, $type, $track, 0;
}

sub command_finish {
    $state{finished} = 1;
    score_final_cults;
    score_final_networks;
    score_final_resources;
    for (@factions) {
        $factions{$_}{passed} = 0;
    }
    @action_required = ( { type => 'gameover' } );
}

sub command_income {
    my $faction_name = shift;
    if ($faction_name) {
        take_income_for_faction $faction_name;
    } else {
        my @order = factions_in_turn_order;
        if (!$state{ledger}->trailing_comment()) {
            $state{ledger}->add_comment(sprintf "Round %d income", $state{round} + 1);
        }
        for (@order) {
            handle_row_internal $_, "income_for_faction";
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

sub valid_player_count {
    if (!defined $player_count) { return 1 }
    if (@players == $player_count) { return 1 }

    return 0;
}

sub check_player_count {
    return if !defined $player_count;

    if (@players > $player_count) {
        die "Too many players (wanted $player_count)\n"
    }

    for my $player (@players) {
        if (!$player->{username}) {
            die "The players must be specified by usernames in public games (player $player->{name} isn't)\n"
        }
    }
}

sub command_randomize_v1 {
    if (!valid_player_count) {
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
    } keys %tiles;

    
    while (@bon != @players + 3) {
        handle_row_internal "", "delete ".(shift @bon);
    }

    @players = mt_shuffle $rand, sort {
        lc $a->{name} cmp lc $b->{name} or $a->{index} <=> $b->{index}
    } @players;
    my $i = 1;
    for (@players) {
        $state{ledger}->add_comment(
            "Player $i: ".($_->{displayname} // $_->{name}));
        ++$i;
    }
}

sub command_start_planning {
    my $faction = shift;

    $faction->{planning} = 1;
    if ($faction->{passed}) {
        command_income;
        command_start;
    }

    allow_full_move $faction;
}

sub leech_decisions_required {
    my $faction = shift;

    return grep {
        $_->{type} eq 'leech' and $_->{faction} eq $faction->{name}
    } @action_required;
}

sub non_leech_action_required {
    return scalar grep { $_->{type} ne 'leech' } @action_required;
}

sub full_action_required {
    return scalar grep { $_->{type} eq 'full' } @action_required;
}

sub command {
    my ($faction_name, $command) = @_;
    my $faction = $faction_name ? $factions{$faction_name} : undef;
    my $ledger = $state{ledger};

    my $assert_faction = sub {
        die "Need faction for command $command\n" if !$faction;
        $faction;
    };

    my $assert_active_faction = sub {
        $assert_faction->();
        die "Command invalid when not active player\n" if
            $faction_name ne $active_faction and
            $state{round} > 0 and
            !$state{finished};
        $faction;
    };

    if ($faction) {
        $faction->{waiting} = 0;
    }

    if ($command =~ /^([+-])(\d*)(\w+)(?: for (\w+))?$/i) {
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));        
        my $delta = $sign * $count;
        my $type = uc $3;

        if (!$state{round} and $type =~ /BON/) {
            handle_row_internal $faction_name, "pass $type";
            return 0;
        }

        command_adjust_resources $assert_faction->(), $delta, $type, lc $4;
    } elsif ($command =~ /^build (\w+)$/i) {
        command_build $assert_active_faction->(), uc $1;
    } elsif ($command =~ /^upgrade (\w+) to ([\w ]+)$/i) {
        die "Can't upgrade in setup phase\n" if !$state{round};
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
        setup lc $1, $2, $3;
    } elsif ($command =~ /delete (\w+)$/i) {
        my $name = uc $1;

        maybe_setup_pool;
        my $x = ($faction ? $faction : \%pool);

        $state{ledger}->add_comment("Removing tile $name");
        if (!defined $x->{$name} or
            $name eq 'TELEPORT_TO' or
            $x->{$name} <= 1) {
            delete $x->{$name};
        } else {
            $x->{$name}--;
        }
    } elsif ($command =~ /^income$/i) {
        return 0 if non_leech_action_required;
        for (@factions) {
            command_income $_ if !$factions{$_}{income_taken};
        }
    } elsif ($command =~ /^income_for_faction$/i) {
        command_income $faction_name;
    } elsif ($command =~ /^advance (ship|dig)/i) {
        command_advance $assert_faction->(), lc $1;
    } elsif ($command =~ /^score (.*)/i) {
        my $setup = uc $1;
        @score_tiles = split /,/, $setup;
        die "Invalid scoring tile setup: $setup\n" if @score_tiles != 6;
        for my $i (0..$#score_tiles) {
            my $r = $i + 1;
            my $desc = $tiles{$score_tiles[$i]}{vp_display};
            $state{ledger}->add_comment("Round $r scoring: $score_tiles[$i], $desc");
        }
    } elsif ($command =~ /^finish$/i) {
        return 0 if non_leech_action_required;
        command_finish;
    } elsif ($command =~ /^abort$/i) {
        $state{finished} = 1;
        $state{aborted} = 1;
        @action_required = ( { type => 'gameover' } );
    } elsif ($command =~ /^score_resources$/i) {
        score_final_resources_for_faction $faction_name;
    } elsif ($command =~ /^admin email (.*)/i) {
        # backwards-compatibility nop
    } elsif ($command =~ /^option (\S+)$/i) {
        my $opt = lc $1;
        my %valid_options = map { ($_, 1) } qw(
            errata-cultist-power
            mini-expansion-1
            shipping-bonus
            email-notify
            strict-leech);
        if (!$valid_options{$opt}) {
            die "Unknown option $opt\n";
        }
        $options{$opt} = 1;
        $state{ledger}->add_comment("option $opt");
    } elsif ($command =~ /^player (\S+)(?: email (\S*))?(?: username (\S+))?$/i) {
        push @players, {
            name => $1,
            email => $2,
            username => $3,
            index => scalar @players,
        };
        check_player_count;
    } elsif ($command =~ /^player-count (\d+)$/i) {
        $player_count = 1*$1;
        check_player_count;
    } elsif ($command =~ /^randomize v1 seed (.*)/i) {
        maybe_setup_pool;
        command_randomize_v1 $1;
    } elsif ($command =~ /^wait$/i) {
        ($assert_faction->())->{waiting} = 1;
    } elsif ($command =~ /^done$/i) {
        ($assert_faction->())->{allowed_sub_actions} = {};
        ($assert_faction->())->{allowed_actions} = 0;
    } elsif ($command =~ /^start_planning$/i) {
        command_start_planning $assert_faction->();
    } else {
        die "Could not parse command '$command'.\n";
    }

    1;
}

sub detect_incomplete_state {
    my ($prefix) = @_;
    my $faction = $factions{$prefix};
    my $ledger = $state{ledger};

    my @extra_action_required = ();

    if ($faction->{SPADE}) {
        push @extra_action_required, {
            type => 'transform',
            amount => $faction->{SPADE}, 
            faction => $prefix
        };
    }

    if ($faction->{FORBID_TF}) {
        delete $faction->{FORBID_TF};
    }

    if ($faction->{FREE_TF}) {
        $ledger->warn("Unused free terraform for $prefix");
        push @extra_action_required, {
            type => 'transform',
            faction => $prefix
        };
    }

    if ($faction->{FREE_TP}) {
        $ledger->warn("Unused free trading post for $prefix\n");
        push @extra_action_required, {
            type => 'upgrade',
            from_building => 'D',
            to_building => 'TP',
            faction => $prefix
        };
    }

    if ($faction->{FREE_D}) {
        $ledger->warn("Unused free dwelling for $prefix\n");
        push @extra_action_required, {
            type => 'dwelling',
            faction => $prefix
        };
    }

    if ($faction->{CULT}) {
        $ledger->warn("Unused cult advance for $prefix\n");
        push @extra_action_required, {
            type => 'cult',
            amount => $faction->{CULT}, 
            faction => $prefix
        };
    }

    if ($faction->{GAIN_FAVOR}) {
        $ledger->warn("favor not taken by $prefix\n");
        push @extra_action_required, {
            type => 'favor',
            amount => $faction->{GAIN_FAVOR}, 
            faction => $prefix
        };
    } else {
        @action_required = grep {
            ($_->{faction} // '') ne $faction->{name} or $_->{type} ne 'favor'
        } @action_required;       
    }

    if ($faction->{GAIN_TW}) {
        $ledger->warn("town tile not taken by $prefix\n");
        push @extra_action_required, {
            type => 'town',
            amount => $faction->{GAIN_TW}, 
            faction => $prefix
        };
    } else {
        @action_required = grep {
            ($_->{faction} // '') ne $faction->{name} or $_->{type} ne 'town'
        } @action_required;       
    }

    if ($faction->{BRIDGE}) {
        $ledger->warn("bridge paid for but not placed\n");
        push @extra_action_required, {
            type => 'bridge',
            faction => $prefix
        };
    } else {
        @action_required = grep {
            ($_->{faction} // '') ne $faction->{name} or $_->{type} ne 'bridge'
        } @action_required;       
    }

    @extra_action_required;
}

sub next_faction_in_turn {
    my $faction_name = shift;
    my @f = factions_in_order_from $faction_name;

    if (!$state{finished}) {
        for (@f) {
            if (!$factions{$_}{passed}) {
                return $_;
            }
        }
    }

    undef;
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
    }

    grep { $_->[1] } @command_stream;
}

sub maybe_advance_turn {
    my ($faction_name) = @_;

    $state{ledger}->turn($state{round}, $state{turn});

    my $all_passed = 1;
    my $max_order = max map {
        $_->{order}
    } grep {
        $all_passed &&= $_->{passed};
        (!$_->{passed}) or ($_->{name} eq $faction_name)
    } values %factions;

    if ($factions{$faction_name}{order} != $max_order) {
        return;
    }

    if (!$all_passed) {
        $state{turn}++;
    }
}

sub maybe_advance_to_next_player {
    my $faction_name = shift;

    # Check whether the action is incomplete in some way, or if somebody
    # needs to react.
    my (@extra_action_required) = detect_incomplete_state $faction_name;

    if (!$state{round}) {
        return "";
    }

    if ($factions{$faction_name}{planning}) {
        return "";
    }

    push @action_required, @extra_action_required;

    if (@extra_action_required) {
        return "";
    } elsif ($faction_name eq $active_faction and
             !$factions{$faction_name}{allowed_actions}) {
        @action_required = grep {
            $_->{faction} ne $faction_name or
                $_->{type} ne 'full'
        } @action_required;

        $factions{$faction_name}{recent_moves} = [];

        # Advance to the next player, unless everyone has passed
        my $next = next_faction_in_turn $faction_name;
        if (defined $next) {
            push @action_required, { type => 'full',
                                     faction => $next };
            allow_full_move $factions{$next};
            maybe_advance_turn $faction_name;
        }
    }
}

sub check_setup_actions {
    if (!$state{round} and !$state{finished}) {
        if (!valid_player_count) {
            @action_required = ({ type => 'not-started',
                                  player_count => scalar @players,
                                  wanted_player_count => $player_count });
        } elsif (@players and @players != @factions) {
            @action_required = ({
                type => 'faction',
                player => ($players[@factions]{displayname} // $players[@factions]{name}),
                player_index => "player".(1+@factions),
             });
        } elsif (@setup_order) {
            my $type = (@setup_order <= @factions ? 'bonus' : 'dwelling');
            @action_required = ({ type => $type, faction => $setup_order[0] });
            if ($type eq 'bonus') {
                allow_pass $factions{$setup_order[0]};
            } else {
                allow_build $factions{$setup_order[0]};
            }
        } else {
            @action_required = ();
        }
    }
}

sub finish_row {
    my $faction = shift;

    if ($faction) {
        maybe_advance_to_next_player $faction->{name};
    }
    
    if ($state{ledger}->collecting_row()) {
        $state{ledger}->finish_row();
    }
}

sub do_command {
    my $ledger = $state{ledger};
    my ($faction_name, @commands) = @_;
    
    return if !@commands;
    die if @commands > 1;

    if ($faction_name eq 'comment') {
        $state{ledger}->add_comment("@commands");
        return;
    }

    if (!($factions{$faction_name} or $faction_name eq '')) {
        my $faction_list = join ", ", @factions;
        die "Unknown faction: '$faction_name' (expected one of $faction_list)\n";
    }

    if ($faction_name and
        (!$ledger->collecting_row() or
         $faction_name ne $ledger->current_faction()->{name})) {
        $ledger->start_new_row($factions{$faction_name});
    }

    command $faction_name, $commands[0];
    $state{ledger}->add_command($commands[0]);
    if ($state{ledger}->force_finish_row()) {
        finish_row $factions{$faction_name};
    }

    check_setup_actions;
}

sub handle_row_internal {
    do_command @_;
    if ($_[0]) {
        finish_row $factions{$_[0]};
    }
}

sub maybe_do_maintenance {
    if (@factions and !@action_required) {
        my $all_passed = 1;
        my $income_taken = 0;
        for my $faction (values %factions) {
            $all_passed &&= $faction->{passed};
            $income_taken ||= $faction->{income_taken};
        }

        if ($state{round} == 6) {
            command_finish;
            return;
        } 

        if (!$income_taken) {
            finish_row undef;
            command_income '';
        }

        if (!@action_required) {
            finish_row undef;
            command_start;
        }
    }
}

sub play {
    my ($commands, $max_row) = @_;
    my $i = 0;
    $active_faction = '';

    while ($i < @{$commands}) {
        my $this = $commands->[$i];
        my $next = $commands->[$i+1];
        eval {
            do_command $this->[0], $this->[1];
        }; if ($@) {
            finish_row undef;
            die "Error in command '".($this->[1])."': $@";
        }
        if (!defined $next and $active_faction) {
            $factions{$active_faction}{allowed_sub_actions}{burn} = 1;
            $factions{$active_faction}{allowed_sub_actions}{convert} = 1;
        }
        if (($next->[0] // '') ne ($this->[0] // '')) {
            finish_row $factions{$this->[0]};
        }
        $i++;
        maybe_do_maintenance;

        if ($max_row) {
            my $size = $state{ledger}->size();
            if ($size >= ($max_row-1)) {
                return $size;
            }
        }
    }

    return 0;
}

1;
