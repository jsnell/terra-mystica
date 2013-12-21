# Code for tracking what should be happening next in the game.
# Whose turn is it now, what can they do, what can other people do, etc.

package terra_mystica::Acting;

use List::Util qw(max);
use Method::Signatures::Simple;
use Moose;
use JSON;

# Who is playing in this game?
has 'players' => (is => 'rw',
                  traits => ['Array'],
                  default => sub { {} },
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
has 'factions_in_order' => (is => '',
                            traits => ['Array'],
                            default => sub { [] },
                            handles => {
                                faction_count => 'count',
                                push_faction => 'push',
                                factions_in_order => 'elements',
                            });

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
                              action_required_count => 'count',
                              action_required_elements => 'elements',
                              push_action_required => 'push',
                          });

# Which faction is currently acting (a full action, not just a
# async decision on resources).
has 'active_faction' => (is => 'rw');

# What state is the game currently in.
has 'state' => (is => 'rw',
                default => 'wait-for-players');

# Main game data structure
has 'game' => (is => 'rw');

# True if the last player in turn order who hasn't passed has just finished
# their move.
has 'full_turn_played' => (is => 'rw', default => 0);

## Tracking what each player needs to do

method require_action($faction, $action) {
    die "Invalid faction" if !$action or !$faction;
    $action->{faction} = $faction->{name};
    $self->push_action_required($action);
}

method dismiss_action($faction, $type) {
    $self->action_required([
        grep {
            !(($faction->{name} // '') eq ($_->{faction} // '') and
              ($type // '') eq ($_->{type} // ''))
        } $self->action_required_elements()
    ]);
}

method replace_all_actions(@actions) {
    $self->action_required([@actions]);
}

method clear_empty_actions() {
    $self->action_required([grep { $_ ne '' } $self->action_required_elements()]);
}

## Dealing with factions and the setup phase

method setup_action($faction, $kind) {
    $self->shift_setup_order();
}

method register_faction($faction) {
    $self->factions()->{$faction->{name}} = $faction;
    $self->push_faction($faction);

    my @order = map { $_->{name} } $self->factions_in_order();
    my @setup_order = grep { $_ ne 'chaosmagicians' } @order;
    push @setup_order, reverse @setup_order;
    push @setup_order, 'nomads' if $self->factions()->{nomads};

    if ($self->factions()->{chaosmagicians}) {
        push @setup_order, 'chaosmagicians';
    }
    push @setup_order, reverse @order;

    $self->setup_order([@setup_order]);
}

method factions_in_turn_order() {
    my ($start_player) = grep { $_->{start_player} } $self->factions_in_order();
    my @order = $self->factions_in_order_from($start_player);
    my $a = pop @order;
    unshift @order, $a;

    return @order;
}


method factions_in_order_from($faction) {
    my @f = $self->factions_in_order();
    while ($f[-1] != $faction) {
        push @f, shift @f;
    }
    
    @f;
}

## Dealing with the active player.

# Make a faction become the active one
method start_full_move($faction) {
    $self->active_faction($faction);
    
    $faction->{allowed_actions} = 1;
    $faction->{allowed_sub_actions} = {};
    $faction->{allowed_build_locations} = {};
    delete $faction->{TELEPORT_TO};
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
        $faction->{allowed_sub_actions} = $followup if $followup;
    } elsif ($faction->{allowed_actions}) {
        $faction->{allowed_actions}--;
        $faction->{allowed_sub_actions} = $followup if $followup;
        # Taking an action is an implicit "decline"
        terra_mystica::command_decline($faction, undef, undef);
    } else {
        my @unpassed = grep { !$_->{passed} } $self->factions_in_order();
        if (@unpassed == 1 or $faction->{planning}) {
            $self->maybe_advance_to_next_player($faction);

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

    if ($self->player_count() != $self->faction_count()) {
        my $player = $self->players->[$self->faction_count()];
        $self->replace_all_actions({
            type => 'faction',
            player => ($player->{displayname} // $player->{name}),
            player_index => "player".(1+$self->faction_count())});
    } else {
        $self->state('initial-dwellings');
    }
}

method in_initial_dwellings() {
    if ($self->setup_order_count() <= $self->faction_count()) {
        $self->state('initial-bonus');
    } else {
        my $faction_name = $self->setup_order()->[0];
        $self->replace_all_actions(
            {
                type => 'dwelling',
                faction => $faction_name,
            });
        $self->allow_build($self->factions()->{$faction_name});
    }
}

method in_initial_bonus() {
    if ($self->setup_order_count()) {
        my $faction_name = $self->setup_order()->[0];
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

    my $income_taken = 0;
    for my $faction ($self->factions_in_order()) {
        $income_taken ||= $faction->{income_taken};
    }

    if (!$income_taken) {
        terra_mystica::command_income('');
    }

    $self->state('use-income-spades');
}

method in_use_income_spades() {
    if ($self->action_required_count()) {
        return;
    }

    $self->game()->{ledger}->finish_row();
    $self->state('play');
    terra_mystica::command_start();
}

method in_play() {
    if ($self->action_required_count()) {
        return;
    }

    my $all_passed = 1;
    for my $faction ($self->factions_in_order()) {
        $all_passed &&= $faction->{passed};
    }

    if (!$all_passed) {
        return;
    }

    if ($self->game()->{round} == 6) {
        terra_mystica::command_finish();
    } else {
        $self->state('income');
        $self->what_next();
    }
}

method in_abort() {
    $self->replace_all_actions({ type => 'gameover', aborted => 1 });
}

## Switching the turn from one player to the next


method detect_incomplete_turn($faction) {
    my $faction_name = $faction->{name};
    my $ledger = $self->game()->{ledger};
    my $incomplete = 0;

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
        $ledger->warn("Unused cult advance for $faction_name\n");
        $self->require_action($faction, {
            type => 'cult',
            amount => $faction->{CULT}, 
        });
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
    
    $incomplete;
}

method next_faction_in_turn($faction) {
    return if $self->game()->{finished};

    for my $f ($self->factions_in_order_from($faction)) {
        return $f if !$f->{passed};
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

    $self->game()->{ledger}->finish_row();
}

1;
