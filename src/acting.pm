# Code for tracking what should be happening next in the game.
# Whose turn is it now, what can they do, what can other people do, etc.

package terra_mystica::Acting;

use Clone qw(clone);
use List::Util qw(max);
use Method::Signatures::Simple;
use Moose;
use JSON;

# Who is playing in this game?
has 'players' => (is => 'rw',
                  traits => ['Array'],
                  default => sub { [] },
                  handles => {
                      player_count => 'count',
                      add_player => 'push',
                  });

# The factions in the game
has 'factions' => (is => 'rw',
                   traits => ['Hash'],
                   default => sub { {} },
                   handles => {
                       get_faction => 'get',
                   });
has 'raw_factions_in_order' => (is => 'rw',
                            traits => ['Array'],
                            default => sub { [] },
                            handles => {
                                faction_count => 'count',
                                push_faction => 'push',
                                splice => 'splice',
                                all_factions_in_order => 'elements',
                            });

has 'new_faction_order' => (is => 'rw',
                            traits => ['Array'],
                            default => sub { [] });

# What's to be done during the setup
has 'setup_order' => (is => 'rw',
                      traits => ['Array'],
                      default => sub { [] },
                      handles => {
                          setup_order_count => 'count',
                          shift_setup_order => 'shift',
                      });

# What actions / decisions need to be taken by the factions at the moment?
has 'action_required' => (is => 'rw',
                          traits => ['Array'],
                          default => sub { [] },
                          handles => {
                              action_required_elements => 'elements',
                              push_action_required => 'push',
                          });

# Which faction is currently acting (a full action, not just a
# async decision on resources).
has 'active_faction' => (is => 'rw');

# What state is the game currently in.
has 'state' => (is => 'rw',
                default => 'wait-for-players');

# We go through the income -> spade -> unlock cycle twice; once for
# cult income then for normal income, since these are technically
# separate phases.
has 'income_state' => (is => 'rw',
                       default => 'other');

# Main game data structure
has 'game' => (is => 'rw');

# True if the last player in turn order who hasn't passed has just finished
# their move.
has 'full_turn_played' => (is => 'rw', default => 0);

## Tracking what each player needs to do

method action_required_count() {
    scalar grep { !$_->{optional} } @{$self->action_required()};
}

method require_action($faction, $action) {
    die "Invalid faction" if !$action or !$faction;
    return if $faction->{dropped};
    $action->{faction} = $faction->{name};
    for my $old_rec (@{$self->action_required()}) {
        if ($old_rec eq '') {
            $old_rec = $action;
            return;
        }
    }
    $self->push_action_required($action);
}

method dismiss_action($faction, $type) {
    $self->action_required([
        grep {
            !$_ or
            !(($faction->{name} // '') eq ($_->{faction} // '') and
              (!defined $type or 
               $type eq ($_->{type} // '')))
        } $self->action_required_elements()
    ]);
}

method find_actions($faction, $type) {
    grep {
        ($faction->{name} // '') eq ($_->{faction} // '') and
            (!defined $type or $type eq ($_->{type} // ''))
    } $self->action_required_elements()
}

method replace_all_actions(@actions) {
    $self->action_required([@actions]);
}

method clear_empty_actions() {
    $self->action_required([grep { $_ ne '' } $self->action_required_elements()]);
}

method should_wait_for_cultists($cult) {
    my $cult_count = 0;
    my %leech_ids = ();

    if ($self->game()->{options}{'loose-cultist-ordering'}) {
        return 0;
    }

    if (!exists $self->factions()->{cultists}) {
        return 0;
    }
    my $cultists = $self->factions()->{cultists};
    return 0 if !$cultists->{KEY};
        
    for (@{$self->action_required()}) {
        my $faction = ($_->{faction} // '');
        my $from_faction = ($_->{from_faction} // '');
        my $type = $_->{type};
        if (($faction eq 'cultists' and $type eq 'cult')) {
            $cult_count++;
        } elsif ($from_faction eq 'cultists' and $type eq 'leech') {
            if (!$cultists->{leech_cult_gained}{$_->{leech_id}}) {
                $leech_ids{$_->{leech_id}} = 1;
            }
        }
    }

    my $max_advance = $cult_count + keys %leech_ids;
    if ($cultists->{$cult} + $max_advance >= 10) {
        return 1;
    }
    return 0
}

## Dealing with factions and the setup phase

method setup_action($faction, $kind) {
    $self->shift_setup_order();
}

method register_faction($faction) {
    $self->factions()->{$faction->{name}} = $faction;
    $self->push_faction($faction);

    my @order = map {
        $_->{name}
    } grep {
        !$_->{dropped}
    } $self->factions_in_order();
    my @setup_order = map {
        [ $_, 'dwelling' ];
    } grep {
        $_ ne 'chaosmagicians';
    } @order;
    push @setup_order, reverse @setup_order;
    push @setup_order, ['nomads', 'dwelling'] if $self->factions()->{nomads};

    if ($self->factions()->{chaosmagicians}) {
        push @setup_order, ['chaosmagicians', 'dwelling'];
    }
    push @setup_order, map { [ $_, 'bonus'] } reverse @order;

    $self->setup_order([@setup_order]);
}

method factions_in_order($no_dummy) {
    if ($no_dummy) {
        grep { !$_->{dropped} } $self->all_factions_in_order();
    } else {
        $self->all_factions_in_order();
    }
}

method factions_in_turn_order($no_dummy) {
    my ($start_player) = grep { $_->{start_player} } $self->factions_in_order($no_dummy);
    my @order = $self->factions_in_order_from($start_player, $no_dummy);
    my $a = pop @order;
    unshift @order, $a;

    return @order;
}


method factions_in_order_from($faction, $no_dummy) {
    my @f = $self->factions_in_order($no_dummy);

    while ($f[-1] != $faction) {
        push @f, shift @f;
    }
    
    @f;
}

## Dealing with the active player.

# Make a faction become the active one
method start_full_move($faction) {
    $self->active_faction($faction);

    if ($faction->{planning}) {
        if ($faction->{LOSE_CULT}) {
            die "Must pay $faction->{LOSE_CULT} cult steps before next move.\n";
        }
        if ($faction->{UNLOCK_TERRAIN}) {
            die "Must unlock new terrain before next move.\n";
        }
    }

    $faction->{allowed_actions} = 1;
    $faction->{allowed_sub_actions} = {};
    $faction->{allowed_build_locations} = {};
    delete $faction->{require_home_terrain_tf};
    delete $faction->{TELEPORT_TO};
    delete $faction->{cult_blocked};
    delete $faction->{disable_spade_decline};
}

# Signal an intent by a faction to take a sub-action. Either it needs to
# be something they can do as part of or as a consequence of another action
# (e.g. building after transforming), or they must have an available
# full action (either it just became their turn, they got extra actions
# from the CM SH, or they're the only player who hasn't passed).
method require_subaction($faction, $type, $followup) {
    my $ledger = $self->game()->{ledger};

    if (($faction->{allowed_sub_actions}{$type} // 0) > 0) {        
        $faction->{allowed_sub_actions}{$type}--;
        $faction->{allowed_sub_actions} = {%{$followup}} if $followup;
    } elsif ($faction->{allowed_actions}) {
        $faction->{allowed_actions}--;
        $faction->{allowed_sub_actions} = {%{$followup}} if $followup;
        # Taking an action is an implicit "decline"
        if (terra_mystica::command_decline($faction, undef, undef)) {
            terra_mystica::preview_warn("You did not make a decision on some leeching opportunities, automatically declining all power.");
        }
    } elsif ($self->game()->{round} == 0) {
        die "Can't take arbitrary actions during setup.\n";
    } else {
        my @unpassed = grep { !$_->{passed} and !$_->{dropped} } $self->factions_in_order();
        if (@unpassed == 1 or $faction->{planning}) {
            $self->maybe_advance_to_next_player($faction);
            if (!$ledger->force_finish_row()) {
                $ledger->finish_row();
            }
            $ledger->start_new_row($faction);
            $self->start_full_move($faction);
            $self->require_subaction($faction, $type, $followup);
            return;
        } else {
            die "'$type' command not allowed (trying to take multiple actions in one turn?)\n"
        }
    }
}

# The player is allowed to pass without using up a full action.
method allow_pass($faction) {
    $faction->{allowed_sub_actions} = {
        pass => 1,
    };    
}

# The player is allowed to build a dwelling without using up a full action.
method allow_build($faction) {
    $faction->{allowed_sub_actions} = {
        build => 1,
    };
}

# Is the faction currently the active one?
method is_active($faction) {
    defined $self->active_faction() and $faction == $self->active_faction();
}

# Name of action currently active, or undef
method active_faction_name() {
    my $faction = $self->active_faction();
    $faction and $faction->{name};
}

## Tracking the set of players

before add_player => sub {
    my ($self, $player) = @_;
    $player->{index} = $self->player_count();
};

method correct_player_count() {
    my $wanted_count = $self->game()->{player_count};
    if (!defined $wanted_count) { return 1 }
    if ($self->player_count() == $wanted_count) { return 1 }

    return 0;
}

## State machine

# What should be done next in the game? Mostly movement between major
# phases of the game.
method what_next() {
    if ($self->state() eq 'wait-for-players') {
        $self->in_wait_for_players();
    }

    if ($self->state() eq 'select-factions') {
        $self->in_select_factions();
    }

    if ($self->state() eq 'post-setup') {
        $self->in_post_setup();
    }

    if ($self->state() eq 'initial-dwellings') {
        $self->in_initial_dwellings();
    }

    if ($self->state() eq 'initial-bonus') {
        $self->in_initial_bonus();
    }

    if ($self->state() eq 'income') {
        $self->in_income();
    }

    if ($self->state() eq 'use-income-spades') {
        $self->in_use_income_spades();
    }

    if ($self->state() eq 'income-terrain-unlock') {
        $self->in_income_terrain_unlock();
    }

    if ($self->state() eq 'play') {
        $self->in_play();
    }

    if ($self->state() eq 'abort') {
        $self->in_abort();
    }
}

# Request that the game move forward to a new state (but only specific
# transitions are possible).
method advance_state($new_state) {
    # Old-style games had no players, so we must move to faction selection
    # if there's a 'setup' before there any 'player' commands.
    if ($new_state eq 'select-factions') {
        if ($self->state() eq 'wait-for-players') {
            $self->state($new_state);
            $self->what_next();
        }
    }
    
    # Likewise for old-style games we wouldn't know how many players are
    # in the game. So move forward on seeing a 'build' or a 'randomize'.
    if ($new_state eq 'initial-dwellings') {
        if ($self->state() eq 'select-factions') {
            $self->state($new_state);
            $self->what_next();
        }
    }

    # We can always abort the game.
    if ($new_state eq 'abort') {
        $self->state($new_state);
        $self->in_abort();
    }
}

method in_wait_for_players() {
    if (defined $self->game()->{player_count}) {
        my $player_count = $self->player_count();       
        my $wanted_count = $self->game()->{player_count};

        if ($player_count == $wanted_count) {
            $self->state('select-factions');
            return;
        } else {
            $self->replace_all_actions({ type => 'not-started',
                                         player_count => $player_count,
                                         wanted_player_count => $wanted_count });
        }
    } else {
        $self->replace_all_actions();
    }
}

method in_select_factions() {
    if (!$self->player_count()) {
        return;
    }

    my $faction = ($self->factions_in_order())[-1];
    if ($faction) {
        $self->replace_all_actions();
        my ($incomplete) = $self->detect_incomplete_turn($faction);
        if ($incomplete) {
            my $player_index = "player".($self->faction_count());
            for my $record (@{$self->action_required()}) {
                $record->{player_index} = $player_index;
            }
            return;
        }
    }

    my $faction_count = $self->faction_count();

    if ($self->player_count() != $faction_count) {
        my $player = $self->players->[$faction_count];
        my $player_index = "player".(1+$faction_count);
        $self->replace_all_actions({
            type => 'faction',
            player => ($player->{displayname} // $player->{name}),
            player_index => $player_index,
        });
    } else {
        $self->state('post-setup');
    }
}

method in_post_setup() {
    my $incomplete = 0;
    for my $faction ($self->factions_in_order()) {
        my $post_setup = $faction->{post_setup};
        for (keys %{$post_setup}) {
            $faction->{$_} = $post_setup->{$_};
        }
        delete $faction->{post_setup};
        $incomplete += $self->detect_incomplete_turn($faction);
    }
    if (!$incomplete) {
        $self->state('initial-dwellings');
    }
}

method in_initial_dwellings() {
    my $record = $self->setup_order()->[0];

    return if !$record;

    if ($record->[1] eq 'bonus') {
        $self->state('initial-bonus');
    } else {
        my $faction_name = $record->[0];
        $self->replace_all_actions(
            {
                type => 'dwelling',
                faction => $faction_name,
            });
        $self->allow_build($self->factions()->{$faction_name});
    }
}

method in_initial_bonus() {
    my $record = $self->setup_order()->[0];

    if ($self->setup_order_count()) {
        my $faction_name = $record->[0];
        $self->replace_all_actions(
            {
                type => 'bonus',
                faction => $faction_name,
            });
        $self->allow_pass($self->factions()->{$faction_name});
    } else {
        $self->replace_all_actions();
        $self->game()->{ledger}->finish_row();
        $self->state('income');
    }
}

method in_income() {
    if ($self->action_required_count()) {
        return;
    }

    my $mask = 15;

    if ($self->income_state() eq 'cult') {
        $mask = 1;
    } elsif ($self->income_state() eq 'other') {
        $mask = 14;
    }

    my $income_taken = 0;
    for my $faction ($self->factions_in_order()) {
        $income_taken ||= ($faction->{income_taken} & $mask);
    }

    if (!$income_taken) {
        terra_mystica::command_income('', $self->income_state());
    }

    $self->state('use-income-spades');
}

method in_use_income_spades() {
    if ($self->action_required_count()) {
        return;
    }

    $self->state('income-terrain-unlock');
}

method in_income_terrain_unlock() {
    for my $faction ($self->factions_in_order()) {
        if ($faction->{UNLOCK_TERRAIN}) {
            $self->require_action($faction,
                                  { type => 'unlock-terrain',
                                    count => $faction->{UNLOCK_TERRAIN} });
        }
    }

    if ($self->action_required_count()) {
        return;
    }

    if ($self->income_state() eq 'cult') {
        $self->income_state('other');
        $self->state('income');
        $self->what_next();
    } else {
        $self->game()->{ledger}->finish_row();
        $self->state('play');
        terra_mystica::command_start();
    }
}

method in_play() {
    if ($self->action_required_count()) {
        return;
    }

    my $all_passed = 1;
    for my $faction ($self->factions_in_order()) {
        $all_passed &&= ($faction->{passed} || $faction->{dropped});
    }

    if (!$all_passed) {
        return;
    }

    if ($self->game()->{round} == 6) {
        terra_mystica::command_finish();
    } else {
        $self->state('income');
        if ($self->game()->{options}{'merge-income-phases'}) {
            $self->income_state('all');
        } else {
            $self->income_state('cult');
        }
        $self->what_next();
    }
}

method in_abort() {
    $self->replace_all_actions({ type => 'gameover', aborted => 1 });       
    $self->game()->{aborted} = 1;
    $self->game()->{finished} = 1;
}

## Switching the turn from one player to the next


method detect_incomplete_turn($faction) {
    my $faction_name = $faction->{name};
    my $ledger = $self->game()->{ledger};
    my $incomplete = 0;

    return 0 if $faction->{dropped};

    if ($faction->{PICK_COLOR}) {
        $incomplete = 1;
        $self->require_action($faction, {
            type => 'pick-color',
        });
    }

    if ($faction->{SPADE}) {
        $incomplete = 1;
        $self->require_action($faction, {
            type => 'transform',
            amount => $faction->{SPADE}, 
        });
    }

    # Hm, this doesn't feel right. 
    if ($faction->{FORBID_TF}) {
        delete $faction->{FORBID_TF};
    }

    if ($faction->{FREE_TF}) {
        $incomplete = 1;
        $ledger->warn("Unused free terraform for $faction_name");
        $self->require_action($faction, {
            type => 'transform',
        });
    }

    if ($faction->{VOLCANO_TF}) {
        $incomplete = 1;
        $ledger->warn("Unused terraform for $faction_name");
        $self->require_action($faction, {
            type => 'transform',
        });
    }

    if ($faction->{LOSE_CULT}) {
        $self->require_action($faction, {
            type => 'lose-cult',
            amount => $faction->{LOSE_CULT}
        });
        return 1;
    }

    if ($faction->{FREE_TP}) {
        $incomplete = 1;
        $ledger->warn("Unused free trading post for $faction_name\n");
        $self->require_action($faction, {
            type => 'upgrade',
            from_building => 'D',
            to_building => 'TP',
        });
    }

    if ($faction->{FREE_D}) {
        $incomplete = 1;
        $ledger->warn("Unused free dwelling for $faction_name\n");
        $self->require_action($faction, {
            type => 'dwelling',
            faction => $faction_name
        });
    }

    if ($faction->{CULT}) {
        $incomplete = 1;
        $self->require_action($faction, {
            type => 'cult',
            amount => $faction->{CULT}, 
        });
        return 1;
    }

    if ($faction->{GAIN_FAVOR}) {
        $incomplete = 1;
        $ledger->warn("favor not taken by $faction_name\n");
        $self->require_action($faction, {
            type => 'favor',
            amount => $faction->{GAIN_FAVOR}, 
        });
    } else {
        $self->dismiss_action($faction, 'favor');
    }

    if ($faction->{GAIN_TW}) {
        $incomplete = 1;
        $ledger->warn("town tile not taken by $faction_name\n");
        $self->require_action($faction, {
            type => 'town',
            amount => $faction->{GAIN_TW}, 
        });
    } else {
        $self->dismiss_action($faction, 'town');
    }

    if ($faction->{BRIDGE}) {
        $incomplete = 1;
        $ledger->warn("bridge paid for but not placed\n");
        $self->require_action($faction, {
            type => 'bridge',
        });
    } else {
        $self->dismiss_action($faction, 'bridge');
    }
    
    if ($faction->{CONVERT_W_TO_P} and
        $self->game()->{options}{'strict-darkling-sh'}) {
        $incomplete = 1;
        $self->require_action($faction, {
            type => 'convert',
            from => 'W',
            amount => $faction->{CONVERT_W_TO_P}, 
            to => 'P',
            optional => 1,
        });
    }

    if ($faction->{GAIN_P3_FOR_VP}) {
        $self->require_action($faction, {
            type => 'gain-token',
            amount => $faction->{GAIN_P3_FOR_VP},
            from => 'VP',
            to => 'P3',
        });
    }

    if ($faction->{UNLOCK_TERRAIN}) {
        $incomplete = 1;
        $self->require_action($faction, {
            type => 'unlock-terrain',
            count => $faction->{UNLOCK_TERRAIN},
        });
    }

    $incomplete;
}

method next_faction_in_turn($faction) {
    return if $self->game()->{finished};

    for my $f ($self->factions_in_order_from($faction)) {
        return $f if !$f->{passed} and !$f->{dropped};
    }

    undef;
}

method maybe_advance_turn($faction, $next) {
    my $game = $self->game();

    if ($self->full_turn_played()) {
        $self->full_turn_played(0);
        $game->{turn}++;
    }

    if ($faction->{order} >= $next->{order}) {
        $self->full_turn_played(1);
    }

    $game->{ledger}->turn($game->{round},
                          $game->{turn});
}

method maybe_advance_to_next_player($faction) {
    my $faction_name = $faction->{name};

    # Check whether the action is incomplete in some way.
    my ($incomplete) = $self->detect_incomplete_turn($faction);

    if (!$self->game()->{round}) {
        return;
    }

    if ($faction->{planning}) {
        return;
    }

    if (!$incomplete and
        $self->is_active($faction) and
        !$faction->{allowed_actions}) {
        $self->dismiss_action($faction, 'full');

        # Advance to the next player, unless everyone has passed
        my $next = $self->next_faction_in_turn($faction);
        if (defined $next) {
            $self->require_action($next, { type => 'full' });
            $self->start_full_move($next);
            $self->maybe_advance_turn($faction, $next);
        }
        $faction->{recent_moves} = [];
    }

    if (@{$self->new_faction_order()}) {
        $self->raw_factions_in_order($self->new_faction_order());
        $self->new_faction_order([]);
    }

    $self->game()->{ledger}->finish_row();
}

1;
