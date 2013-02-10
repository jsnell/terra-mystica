package terra_mystica;

use strict;

use buildings;
use cults;
use factions;
use map;
use income;
use resources;
use scoring;
use tiles;
use towns;

my $action_taken;
my @warn = ();
my $turn = 0;
my $min_active_order = 0;

sub handle_row;

sub command_adjust_resources {
    my ($faction, $delta, $type, $source) = @_;
    my $faction_name = $faction->{name};

    adjust_resource $faction, $type, $delta, $source;

    if (!$round) {
        if ($faction_name ne $setup_order[0]) {
            die "Expected $setup_order[0] to pick bonus, not $faction_name\n"
        }
        shift @setup_order;
    }

    # Small hack: always remove the notifier for a cultist special cult
    # increase. Needs to be done like this, since we don't want + / - to
    # count as full actions.
    @action_required = grep {
        $_->{faction} ne $faction->{name} or $_->{type} ne 'cult'
    } @action_required;       
}

sub command_build {
    my ($faction, $where) = @_;
    my $faction_name = $faction->{name};

    my $free = ($round == 0);
    my $type = 'D';
    my $color = $faction->{color};

    die "Unknown location '$where'\n" if !$map{$where};

    die "'$where' already contains a $map{$where}{building}\n"
        if $map{$where}{building};

    if (!$round) {
        if ($faction_name ne $setup_order[0]) {
            die "Expected $setup_order[0] to place building, not $faction_name\n"
        }
        shift @setup_order;
    }

    if ($faction->{FREE_D}) {
        $free = 1;
        $faction->{FREE_D}--;
    }

    if ($faction->{TELEPORT_NO_TF}) {
        $faction->{TELEPORT_NO_TF}--;
        die "Transforming terrain forbidden during this action\n"
            if $map{$where}{color} ne $color;
    } else {
        command $faction_name, "transform $where to $color";
    }

    note_leech $faction, $where;

    advance_track $faction, $type, $faction->{buildings}{$type}, $free;

    maybe_score_favor_tile $faction, $type;
    maybe_score_current_score_tile $faction, $type;

    $map{$where}{building} = $type;
    push @{$faction->{locations}}, $where;

    detect_towns_from $faction, $where;
    $action_taken++;
}

sub command_upgrade {
    my ($faction, $where, $type) = @_;

    die "Unknown location '$where'\n" if !$map{$where};

    my $color = $faction->{color};
    die "$where has wrong color ($color vs $map{$where}{color})\n" if
        $map{$where}{color} ne $color;

    my %wanted_oldtype = (TP => 'D', TE => 'TP', SH => 'TP', SA => 'TE');
    my $oldtype = $map{$where}{building};

    if ($oldtype ne $wanted_oldtype{$type}) {
        die "$where contains ə $oldtype, wanted $wanted_oldtype{$type}\n"
    }

    note_leech $faction, $where;

    my $free = 0;
    if ($type eq 'TP') {
        if ($faction->{FREE_TP}) {
            $free = 1;
            $faction->{FREE_TP}--;
        } else {
            if (!keys %leech) {
                my $cost = $faction->{buildings}{$type}{advance_cost}{C};
                adjust_resource $faction, "C", -${cost};
            }
        }
    }

    $faction->{buildings}{$oldtype}{level}--;
    advance_track $faction, $type, $faction->{buildings}{$type}, $free;

    maybe_score_favor_tile $faction, $type;
    maybe_score_current_score_tile $faction, $type;

    $map{$where}{building} = $type;

    detect_towns_from $faction, $where;
    $action_taken++;
}

sub command_send {
    my ($faction, $cult) = @_;

    die "Unknown cult track $cult\n" if !grep { $_ eq $cult } @cults;

    my $gain = { $cult => 1 };
    for (1..4) {
        my $where = "$cult$_";
        if (!$cults{$where}{building}) {
            $gain = $cults{$where}{gain};
            delete $cults{$where}{gain};
            $cults{$where}{building} = 'P';
            $cults{$where}{color} = $faction->{color};
            $faction->{MAX_P}--;
            last;
        }
    }

    gain $faction, $gain;

    adjust_resource $faction, "P", -1;
    $action_taken++;
}

sub command_convert {
    my ($faction,
        $from_count, $from_type,
        $to_count, $to_type) = @_;

    my %exchange_rates = (
        PW => { C => 1, W => 3, P => 5 },
        W => { C => 1 },
        P => { C => 1, W => 1 },
        C => { VP => 3 }
        );

    if ($faction->{exchange_rates}) {
        for my $from_key (keys %{$faction->{exchange_rates}}) {
            my $from = $faction->{exchange_rates}{$from_key};
            for my $to_key (keys %{$from}) {
                $exchange_rates{$from_key}{$to_key} = $from->{$to_key};
            }
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
    my ($faction, $pw) = @_;
    my $faction_name = $faction->{name};

    my $actual_pw = gain_power $faction, $pw;
    my $vp = $actual_pw - 1;

    my $found_leech_record = 0;
    for (@action_required) {
        next if $_->{faction} ne $faction_name;
        next if $_->{type} ne 'leech';
        next if $_->{amount} ne $pw and $_->{amount} ne $actual_pw;

        if ($_->{from_faction} eq 'cultists') {
            push @action_required, { type => 'cult',
                                     amount => 1, 
                                     faction => 'cultists' };
        }

        $_ = '';
        $found_leech_record = 1;
        last;
    }

    if ($found_leech_record) {
        @action_required = grep { $_ ne '' } @action_required;
    } else {
	push @warn, "invalid leech amount $pw (accepting anyway)";
    }

    if ($actual_pw > 0) {
	adjust_resource $faction, 'VP', -$vp, 'leech';
    }
}

sub command_transform {
    my ($faction, $where, $color) = @_;
    my $faction_name = $faction->{name};

    check_reachable $faction, $where;

    if ($map{$where}{building}) {
        die "Can't transform $where to $color, already contains a building\n"
    }

    my $color_difference = color_difference $map{$where}{color}, $color;

    if ($faction_name eq 'giants' and $color_difference != 0) {
        $color_difference = 2;
    }

    if ($faction->{FREE_TF}) {
        adjust_resource $faction, 'FREE_TF', -1;
    } else {
        adjust_resource $faction, 'SHOVEL', -$color_difference;
    }

    $map{$where}{color} = $color;

    detect_towns_from $faction, $where;
    $action_taken++;
}

sub command_bridge {        
    my ($faction, $from, $to) = @_;

    $map{$from}{adjacent}{$to} = 1;
    $map{$to}{adjacent}{$from} = 1;

    push @bridges, {from => $from, to => $to, color => $faction->{color}};

    detect_towns_from $faction, $from;
    detect_towns_from $faction, $to;
    $action_taken++;
}

sub command_pass {
    my ($faction, $bon) = @_;
    my $faction_name = $faction->{name};

    my $discard;

    # XXX hack
    if ($faction_name eq 'engineers' and
        $faction->{buildings}{SH}{level}) {
        my $color = 'gray';
        for my $bridge (@bridges) {
            if ($bridge->{color} eq $color and
                $map{$bridge->{from}}{building} and
                $map{$bridge->{from}}{color} eq $color and
                $map{$bridge->{to}}{building} and
                $map{$bridge->{to}}{color} eq $color) {
                adjust_resource $faction, 'VP', 3, 'SH';
            }
        }            
    }

    my $first_to_pass = 1;
    for (values %factions) {
        $first_to_pass = 0 if $_->{passed};
    }
    if ($first_to_pass) {
        $_->{start_player} = 0 for values %factions;
        $faction->{start_player} = 1;
    }

    $faction->{passed} = 1;
    for (keys %{$faction}) {
        next if !$faction->{$_};

        if (/^BON/) {
            $discard = $_;
        }

        my $pass_vp = $tiles{$_}{pass_vp};
        if ($pass_vp) {
            for my $type (keys %{$pass_vp}) {
                my $x = $pass_vp->{$type}[$faction->{buildings}{$type}{level}];
                adjust_resource $faction, 'VP', $x, $_;
            }
        }                
    }

    if ($bon) {
        adjust_resource $faction, $bon, 1;
    }
    if ($discard) {
        adjust_resource $faction, $discard, -1;
    }

    $action_taken++;
}

sub command_action {
    my ($faction, $action) = @_;
    my $faction_name = $faction->{name};
    
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
    $action_taken++;
}

sub command_start {
    $round++;
    $turn = 0;
    $min_active_order = 0;

    for my $faction_name (@factions) {
        my $faction = $factions{$faction_name};
        die "Round $round income not taken for $faction_name\n" if
            !$faction->{income_taken};
        $faction->{income_taken} = 0;
        $faction->{passed} = 0 for keys %factions;
    }

    $map{$_}{blocked} = 0 for keys %map;
    for (1..9) {
        if ($pool{"BON$_"}) {
            $bonus_coins{"BON$_"}{C}++;
        }
    }

    push @ledger, { comment => "Start round $round" };

    my @order = factions_in_turn_order;
    my $i = 0;
    for (@order) {
        $factions{$_}{order} = $i++;
    }

    my $start_player = $order[0];
    push @action_required, { type => 'full',
                             faction => $start_player };
}

sub command_connect {
    my ($faction, $from, $to) = @_;
    my $faction_name = $faction->{name};

    die "Only mermaids can use 'connect'\n" if $faction_name ne 'mermaids';
    
    $map{$from}{adjacent}{$to} = 1;
    $map{$to}{adjacent}{$from} = 1;

    die "$to and $from must be one river space away\n" if
        $map{$from}{range}{1}{$to} ne 1;

    detect_towns_from $faction, $from;
}

sub command_advance {
    my ($faction, $type) = @_;

    my $track = $faction->{$type};
    advance_track $faction, $type, $track, 0;
    $action_taken++;
}

sub command {
    my ($faction_name, $command) = @_;
    my $faction = $faction_name ? $factions{$faction_name} : undef;

    my $assert_faction = sub {
        die "Need faction for command $command\n" if !$faction;
        $faction;
    };

    if ($command =~ /^([+-])(\d*)(\w+)(?: for (\w+))?$/) {
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));
        my $delta = $sign * $count;
        command_adjust_resources $assert_faction->(), $delta, uc $3, $4;
    }  elsif ($command =~ /^build (\w+)$/) {
        command_build $assert_faction->(), uc $1;
    } elsif ($command =~ /^upgrade (\w+) to ([\w ]+)$/) {
        die "Can't upgrade in setup phase\n" if !$round;
        command_upgrade $assert_faction->(), uc $1, alias_building uc $2;
    } elsif ($command =~ /^send (p|priest) to (\w+)$/) {
        command_send $assert_faction->(), uc $2;
    } elsif ($command =~ /^convert (\d+)?\s*(\w+) to (\d+)?\s*(\w+)$/) {
        my $from_count = $1 || 1;
        my $from_type = alias_resource uc $2;
        my $to_count = $3 || 1;
        my $to_type = alias_resource uc $4;

        command_convert($assert_faction->(),
                        $from_count, $from_type,
                        $to_count, $to_type);
    } elsif ($command =~ /^burn (\d+)$/) {
        $assert_faction->();
        adjust_resource $faction, 'P2', -2*$1;
        adjust_resource $faction, 'P3', $1;
    } elsif ($command =~ /^leech (\d+)$/) {
        command_leech $assert_faction->(), $1;
    } elsif ($command =~ /^decline$/) { 
        $assert_faction->();
        @action_required = grep {
            $_->{faction} ne $faction_name or $_->{type} ne 'leech'
        } @action_required;       
    } elsif ($command =~ /^transform (\w+) to (\w+)$/) {
        command_transform $assert_faction->(), uc $1, lc $2;
    } elsif ($command =~ /^dig (\d+)/) {
        $assert_faction->();
        my $cost = $faction->{dig}{cost}[$faction->{dig}{level}];
        my $gain = $faction->{dig}{gain}[$faction->{dig}{level}];

        adjust_resource $faction, 'SHOVEL', $1;
        pay $faction, $cost for 1..$1;
        gain $faction, $gain, 'faction' for 1..$1;
    } elsif ($command =~ /^bridge (\w+):(\w+)$/) {
        command_bridge $assert_faction->(), uc $1, uc $2;
    } elsif ($command =~ /^connect (\w+):(\w+)$/) {
        command_connect $assert_faction->(), uc $1, uc $2;
    } elsif ($command =~ /^pass(?: (\w+))?$/) {
        command_pass $assert_faction->(), uc ($1 // '');
    } elsif ($command =~ /^action (\w+)$/) {
        command_action $assert_faction->(), uc $1;
    } elsif ($command =~ /^start$/) {
        command_start;
    } elsif ($command =~ /^setup (\w+)(?: for (\S+))?$/) {
        setup $1, $2;
    } elsif ($command =~ /delete (\w+)$/) {
        delete $pool{uc $1};
    } elsif ($command =~ /^income$/) {
        if ($faction_name) {
            take_income_for_faction $faction_name;
        } else {
            my @order = factions_in_turn_order;
            if (!exists $ledger[-1]->{comment}) {
                push @ledger, {
                    comment => sprintf "Round %d income", $round + 1
                };
            }
            for (@order) {
                handle_row "$_: income";
            }
        }
    } elsif ($command =~ /^advance (ship|dig)/) {
        command_advance $assert_faction->(), $1;
    } elsif ($command =~ /^score (.*)/) {
        my $setup = uc $1;
        @score_tiles = split /,/, $setup;
        die "Invalid scoring tile setup: $setup\n" if @score_tiles != 6;
    } elsif ($command =~ /^finish$/) {
        score_final_cults;
        score_final_networks;
        score_final_resources;
        for (@factions) {
            $factions{$_}{passed} = 0;
        }
        @action_required = ( { type => 'gameover' } );
    } elsif ($command =~ /^score_resources$/) {
        score_final_resources_for_faction $faction_name;
    } else {
        die "Could not parse command '$command'.\n";
    }
}

sub detect_incomplete_state {
    my ($prefix) = @_;
    my $faction = $factions{$prefix};

    my @extra_action_required = ();
    my $warn = (@warn ? $warn[0] : '');

    if ($faction->{SHOVEL}) {
        $warn = "Unused shovels for $prefix\n";
        if (!$faction->{passed}) {
            $faction->{SHOVEL} = 0;
        }
    }

    if ($faction->{FORBID_TF}) {
        delete $faction->{FORBID_TF};
    }

    if ($faction->{FREE_TF}) {
        $warn = "Unused free terraform for $prefix\n";
    }

    if ($faction->{FREE_TP}) {
        $warn = "Unused free trading post for $prefix\n";
    }

    if ($faction->{CULT}) {
        $warn = "Unused cult advance for $prefix\n";
        push @extra_action_required, {
            type => 'cult',
            amount => $faction->{CULT}, 
            faction => $prefix
        };
    }

    if ($faction->{GAIN_FAVOR}) {
        $warn = "favor not taken by $prefix\n";
        push @extra_action_required, {
            type => 'favor',
            amount => $faction->{GAIN_FAVOR}, 
            faction => $prefix
        };
    }

    if ($faction->{GAIN_TW}) {
        $warn = "town tile not taken by $prefix\n";
        push @extra_action_required, {
            type => 'town',
            amount => $faction->{GAIN_TW}, 
            faction => $prefix
        };
    }

    ($warn, @extra_action_required);
}

sub next_faction_in_turn {
    my $faction_name = shift;
    my @f = factions_in_order_from $faction_name;

    for (@f) {
        if (!$factions{$_}{passed}) {
            return $_;
        }
    }

    undef;
}

sub clean_commands {
    local $_ = shift;
    my $prefix = '';

    # Remove comments
    if (s/#(.*)//) {
        if ($1 ne '') {
            push @ledger, { comment => $1 };
        }
    }

    # Clean up whitespace
    s/\s+/ /g;

    # Parse the prefix
    if (s/^(.*?)://) {
        $prefix = lc $1;
    }

    # Split subcommands, and clean them up
    my @commands = split /[.]/, $_;
    for (@commands) {
        s/^\s+//;
        s/\s+$//;
        s/(\W)\s(\w)/$1$2/g;
        s/(\w)\s(\W)/$1$2/g;
    }

    return ($prefix, grep { /\S/ } @commands);
}

sub pretty_resource_delta {
    for my $x (@_) {
        $x->{PW} = $x->{P2} + 2 * $x->{P3};
        $x->{CULT} += $x->{$_} for @cults;
    }

    my (%old_data) = %{+shift};
    my (%new_data) = %{+shift};

    my @fields = keys %old_data;
    my %delta = map { $_, $new_data{$_} - $old_data{$_} } @fields;

    my %pretty_delta = map { $_, { delta => $delta{$_},
                                   value => $new_data{$_} } } @fields;
    $pretty_delta{PW}{value} = sprintf "%d/%d/%d", @new_data{'P1','P2','P3'};
    $pretty_delta{CULT}{value} = sprintf "%d/%d/%d/%d", @new_data{@cults};

    %pretty_delta;
}

sub maybe_advance_turn {
    my ($faction_name, $next) = @_;

    if ($factions{$faction_name}{order} > $min_active_order) {
        return;
    }

    $min_active_order = min map { $_->{order}
    } grep { (!$_->{passed}) or ($_->{name} eq $faction_name)
    } values %factions;

    $turn++;

    return if exists $ledger[-1]->{comment};
    push @ledger, { comment => "Round $round, turn $turn" };
}

sub maybe_advance_to_next_player {
    my $faction_name = shift;

    # Check whether the action is incomplete in some way, or if somebody
    # needs to react.
    my ($warn, @extra_action_required) = detect_incomplete_state $faction_name;

    if (!$round) {
        if (@setup_order) {
            my $type = (@setup_order <= @factions ? 'bonus' : 'dwelling');
            @action_required = ({ type => $type, faction => $setup_order[0] });
            return $warn;
        } else {
            @action_required = ();
            return $warn;
        }
    }

    if (!$action_taken) {
        return $warn
    }

    my $last  = (grep { $_->{type} eq 'full' } @action_required)[-1];
    if ($last) {
        $last = $last->{faction};
        if ($faction_name ne $last) {
            $warn = "'$faction_name' took an action, expected '$last'"
        }
    }

    # Remove all of this faction's todo items
    @action_required = grep { $_->{faction} ne $faction_name } @action_required;
    # And then possibly add new ones if there was something wrong with the
    # action.
    push @action_required, @extra_action_required;

    # Advance to the next player, unless everyone has passed
    my $next = next_faction_in_turn $faction_name;
    if (defined $next) {
        push @action_required, { type => 'full',
                                 faction => $next };
        maybe_advance_turn $faction_name;
    }

    return $warn;
}

sub handle_row {
    my ($faction_name, @commands) = clean_commands @_;

    return if !@commands;

    if (!($factions{$faction_name} or $faction_name eq '')) {
        my $faction_list = join ", ", @factions;
        die "Unknown faction: '$faction_name' (expected one of $faction_list)\n";
    }

    %leech = ();
    @warn = ();
    $action_taken = 0;

    # Store the resource counts for computing a delta
    my @fields = qw(VP C W P P1 P2 P3 PW FIRE WATER EARTH AIR CULT);
    my %old_data = ();
    if ($faction_name) {
        %old_data = map { $_, $factions{$faction_name}{$_} } @fields; 
    }

    # Execute commands.
    for my $command (@commands) {
        command $faction_name, lc $command;
    }

    if (!$faction_name) {
        return;
    }

    # Compute the delta
    my %new_data = map { $_, $factions{$faction_name}{$_} } @fields;
    my %pretty_delta = pretty_resource_delta \%old_data, \%new_data;

    my $warn = maybe_advance_to_next_player $faction_name;
    my $info = { faction => $faction_name,
                 leech => { %leech },
                 warning => $warn,
                 commands => (join ". ", @commands),
                 map { $_, $pretty_delta{$_} } @fields};
    push @ledger, $info;
}

1;
