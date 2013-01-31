package terra_mystica;

use strict;

use cults;
use factions;
use map;
use resources;
use scoring;
use tiles;
use towns;

my $action_taken;

sub alias_building;
sub handle_row;
sub note_leech;
sub take_income_for_faction;

sub command_adjust_resources {
    my ($faction, $delta, $type) = @_;

    adjust_resource $faction->{name}, $type, $delta;

    @action_required = grep {
        $_->{faction} ne $faction->{name} or $_->{type} ne 'cult'
    } @action_required;       
}

sub command_build {
    my ($faction, $where) = @_;
    my $faction_name = $faction->{name};

    my $free = ($round == 0);
    my $type = 'D';
    die "Unknown location '$where'\n" if !$map{$where};
    my $color = $faction->{color};

    die "'$where' already contains a $map{$where}{building}\n"
        if $map{$where}{building};

    if ($faction->{FREE_D}) {
        $free = 1;
        $faction->{FREE_D}--;
        # XXX ugly hack -- the two separate functionalities of the
        # Witch Stronghold are coupled together here.
        die "Can't transform terrain when using witch stronghold\n"
            if $map{$where}{color} ne $faction->{color}
    } else {
        command $faction_name, "transform $where to $color";
    }

    note_leech $where, $faction;

    advance_track $faction_name, $type, $faction->{buildings}{$type}, $free;

    maybe_score_favor_tile $faction_name, $type;
    maybe_score_current_score_tile $faction_name, $type;

    $map{$where}{building} = $type;
    push @{$faction->{locations}}, $where;

    detect_towns_from $faction_name, $where;
    $action_taken++;
}

sub command_upgrade {
    my ($faction, $where, $type) = @_;
    my $faction_name = $faction->{name};

    die "Unknown location '$where'\n" if !$map{$where};

    my $free = 0;

    my $color = $faction->{color};
    die "$where has wrong color ($color vs $map{$where}{color})\n" if
        $map{$where}{color} ne $color;

    my %wanted_oldtype = (TP => 'D', TE => 'TP', SH => 'TP', SA => 'TE');
    my $oldtype = $map{$where}{building};

    if ($oldtype ne $wanted_oldtype{$type}) {
        die "$where contains ə $oldtype, wanted $wanted_oldtype{$type}\n"
    }

    note_leech $where, $faction;

    if ($type eq 'TP') {
        if ($faction->{FREE_TP}) {
            $free = 1;
            $faction->{FREE_TP}--;
        } else {
            if (!keys %leech) {
                my $cost = $faction->{buildings}{$type}{advance_cost}{C};
                adjust_resource $faction_name, "C", -${cost};
            }
        }
    }

    $faction->{buildings}{$oldtype}{level}--;
    advance_track $faction_name, $type, $faction->{buildings}{$type}, $free;

    maybe_score_favor_tile $faction_name, $type;
    maybe_score_current_score_tile $faction_name, $type;

    $map{$where}{building} = $type;

    detect_towns_from $faction_name, $where;
    $action_taken++;
}

sub command_send {
    my ($faction, $cult) = @_;
    my $faction_name = $faction->{name};

    die "Unknown cult track $cult\n" if !grep { $_ eq $cult } @cults;

    my $gain = { $cult => 1 };
    for (1..4) {
        my $where = "$cult$_";
        if (!$map{$where}{building}) {
            $gain = $map{$where}{gain};
            delete $map{$where}{gain};
            $map{$where}{building} = 'P';
            $map{$where}{color} = $faction->{color};
            $faction->{MAX_P}--;
            last;
        }
    }

    gain $faction_name, $gain;

    adjust_resource $faction_name, "P", -1;
    $action_taken++;
}

sub command_convert {
    my ($faction,
        $from_count, $from_type,
        $to_count, $to_type) = @_;
    my $faction_name = $faction->{name};

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

    adjust_resource $faction_name, $from_type, -$from_count;
    adjust_resource $faction_name, $to_type, $to_count;
}

sub command_leech {
    my ($faction, $pw) = @_;
    my $faction_name = $faction->{name};

    my $actual_pw = gain_power $faction_name, $pw;
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

        if ($actual_pw > 0) {
            adjust_resource $faction_name, 'VP', -$vp;
        }
    } else {
        # die "Invalid leech of $pw\n";
    }
}

sub command_transform {
    my ($faction, $where, $color) = @_;
    my $faction_name = $faction->{name};

    check_reachable $faction_name, $where;

    if ($map{$where}{building}) {
        die "Can't transform $where to $color, already contains a building\n"
    }

    if ($faction->{FREE_TF}) {
        adjust_resource $faction_name, 'FREE_TF', -1;
    } else {
        my $color_difference = color_difference $map{$where}{color}, $color;

        if ($faction_name eq 'giants' and $color_difference != 0) {
            $color_difference = 2;
        }

        adjust_resource $faction_name, 'SHOVEL', -$color_difference;
    } 

    $map{$where}{color} = $color;

    detect_towns_from $faction_name, $where;
    $action_taken++;
}

sub command_bridge {        
    my ($faction, $from, $to) = @_;
    my $faction_name = $faction->{name};

    $map{$from}{adjacent}{$to} = 1;
    $map{$to}{adjacent}{$from} = 1;

    push @bridges, {from => $from, to => $to, color => $faction->{color}};

    detect_towns_from $faction_name, $from;
    detect_towns_from $faction_name, $to;
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
                adjust_resource $faction_name, 'VP', 3;
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
                adjust_resource $faction_name, 'VP', $x;
            }
        }                
    }

    if ($bon) {
        adjust_resource $faction_name, $bon, 1;
    }
    if ($discard) {
        adjust_resource $faction_name, $discard, -1;
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
        pay $faction_name, $actions{$name}{cost};
        gain $faction_name, $actions{$name}{gain};
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
            $map{"BON$_"}{C}++;
        }
    }

    push @ledger, { comment => "Start round $round" };

    my ($start_player) = grep { $_->{start_player} } values %factions;
    push @action_required, { type => 'full',
                             faction => $start_player->{name} };
}

sub command_connect {
    my ($faction, $from, $to) = @_;
    my $faction_name = $faction->{name};

    die "Only mermaids can use 'connect'\n" if $faction_name ne 'mermaids';
    
    $map{$from}{adjacent}{$to} = 1;
    $map{$to}{adjacent}{$from} = 1;

    die "$to and $from must be one river space away\n" if
        $map{$from}{range}{1}{$to} ne 1;

    detect_towns_from $faction_name, $from;
}

sub command_advance {
    my ($faction, $type) = @_;
    my $faction_name = $faction->{name};

    my $track = $faction->{$type};
    advance_track $faction_name, $type, $track, 0;
    $action_taken++;
}

sub command {
    my ($faction_name, $command) = @_;
    my $faction = $faction_name ? $factions{$faction_name} : undef;

    my $assert_faction = sub {
        die "Need faction for command $command\n" if !$faction;
        $faction;
    };

    if ($command =~ /^([+-])(\d*)(\w+)$/) {
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));
        my $delta = $sign * $count;
        command_adjust_resources $assert_faction->(), $delta, uc $3;
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
        adjust_resource $faction_name, 'P2', -2*$1;
        adjust_resource $faction_name, 'P3', $1;
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

        adjust_resource $faction_name, 'SHOVEL', $1;
        pay $faction_name, $cost for 1..$1;
        gain $faction_name, $gain for 1..$1;
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
            for (@factions) {
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
    } elsif ($command =~ /^score_resources$/) {
        score_final_resources_for_faction $faction_name;
    } else {
        die "Could not parse command '$command'.\n";
    }
}

sub handle_row {
    local $_ = shift;

    # Comment
    if (s/#(.*)//) {
        if ($1 ne '') {
            push @ledger, { comment => $1 };
        }
    }

    s/\s+/ /g;

    my $prefix = '';

    if (s/^(.*?)://) {
        $prefix = lc $1;
    }

    my @commands = split /[.]/, $_;

    for (@commands) {
        s/^\s+//;
        s/\s+$//;
        s/(\W)\s(\w)/$1$2/g;
        s/(\w)\s(\W)/$1$2/g;
    }

    @commands = grep { /\S/ } @commands;

    return if !@commands;

    %leech = ();
    $action_taken = 0;

    if ($factions{$prefix} or $prefix eq '') {
        my @fields = qw(VP C W P P1 P2 P3 PW
                        FIRE WATER EARTH AIR CULT);
        my %old_data = map { $_, $factions{$prefix}{$_} } @fields; 

        for my $command (@commands) {
            command $prefix, lc $command;
        }

        my %new_data = map { $_, $factions{$prefix}{$_} } @fields;

        if ($prefix) {
            $old_data{PW} = $old_data{P2} + 2 * $old_data{P3};
            $new_data{PW} = $new_data{P2} + 2 * $new_data{P3};

            $old_data{CULT} = sum @old_data{@cults};
            $new_data{CULT} = sum @new_data{@cults};

            my %delta = map { $_, $new_data{$_} - $old_data{$_} } @fields;
            my %pretty_delta = map { $_, { delta => $delta{$_},
                                           value => $new_data{$_} } } @fields;
            $pretty_delta{PW}{value} = sprintf "%d/%d/%d",  $new_data{P1}, $new_data{P2}, $new_data{P3};

            $pretty_delta{CULT}{value} = sprintf "%d/%d/%d/%d", $new_data{FIRE}, $new_data{WATER}, $new_data{EARTH}, $new_data{AIR};

            my @extra_action_required = ();
            my $warn = '';
            if ($factions{$prefix}{SHOVEL}) {
                 $warn = "Unused shovels for $prefix\n";
                 if (!$factions{$prefix}{passed}) {
                     $factions{$prefix}{SHOVEL} = 0;
                 }
            }

            if ($factions{$prefix}{FREE_TF}) {
                $warn = "Unused free terraform for $prefix\n";
            }

            if ($factions{$prefix}{FREE_TP}) {
                $warn = "Unused free trading post for $prefix\n";
            }

            if ($factions{$prefix}{CULT}) {
                $warn = "Unused cult advance for $prefix\n";
                push @extra_action_required, {
                    type => 'cult',
                    amount => $factions{$prefix}{CULT}, 
                    faction => $prefix
                };
            }

            if ($factions{$prefix}{GAIN_FAVOR}) {
                $warn = "favor not taken by $prefix\n";
                push @extra_action_required, {
                    type => 'favor',
                    amount => $factions{$prefix}{GAIN_FAVOR}, 
                    faction => $prefix
                };
            }

            if ($factions{$prefix}{GAIN_TW}) {
                $warn = "town tile not taken by $prefix\n";
                push @extra_action_required, {
                    type => 'town',
                    amount => $factions{$prefix}{GAIN_TW}, 
                    faction => $prefix
                };
            }

            if ($action_taken and $round > 0) {

                {
                    my $last = (grep { $_->{type} eq 'full' } @action_required)[-1];
                    if ($last) {
                        $last = $last->{faction};
                        $warn = "'$prefix' took an action, expected '$last'" if $prefix ne $last;
                    }
                }

                @action_required = grep { $_->{faction} ne $prefix } @action_required;
                push @action_required, @extra_action_required;

                my $next = undef;
                my @f = factions_in_order_from $prefix;
                for (@f) {
                    if (!$factions{$_}{passed}) {
                        $next = $_;
                        last;
                    }
                }

                if (defined $next) {
                    push @action_required, { type => 'full',
                                             faction => $next };
                }
            }

            push @ledger, { faction => $prefix,
                            warning => $warn,
                            leech => { %leech },
                            commands => (join ". ", @commands),
                            map { $_, $pretty_delta{$_} } @fields};
        }
    } else {
        die "Unknown prefix: '$prefix' (expected one of ".
            (join ", ", keys %factions).
            ")\n";
    }
}

1;
