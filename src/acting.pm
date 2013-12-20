# Code for tracking what should be happening next in the game.
# Whose turn is it now, what can they do, what can other people do, etc.

package terra_mystica::Acting;
use JSON;
use Mouse;

# Who is playing in this game?
has 'players' => (is => 'rw');

# What's to be done during the setup
has 'setup_order' => (is => 'rw', default => sub { [] });

# What actions / decisions need to be taken by the factions at the moment?
has 'action_required' => (is => 'rw', default => sub { [] });

# Which faction is currently acting (a full action, not just a
# async decision on resources).
has 'active_faction' => (is => 'rw');

# What state is the game currently in.
has 'state' => (is => 'rw',
                default => 'wait-for-players');

# Main game data structure
has 'game' => (is => 'rw');

## Tracking what each player needs to do

sub action_required_count {
    my ($self) = @_;
    return scalar @{$self->action_required()};
}

sub require_action {
    my ($self, $faction, $action) = @_;
    die if !$action or !$faction;
    $action->{faction} = $faction->{name};
    push @{$self->action_required()}, $action;
}

sub dismiss_action {
    my ($self, $faction, $type) = @_;
    $self->action_required([
        grep {
            !((!defined $faction or $_->{faction} eq $faction->{name}) and
              (!defined $type or $_->{type} eq $type))
        } @{$self->action_required}
    ]);
}

sub replace_all_actions {
    my ($self, @actions) = @_;
    $self->action_required([@actions]);
}

sub clear_empty_actions {
    my ($self) = @_;
    $self->action_required([grep { $_ ne '' } @{$self->action_required()}]);
}

## Dealing with the setup phase

sub setup_order_count {
    my ($self) = @_;
    return scalar @{$self->setup_order()};
}

sub setup_action {
    my ($self, $faction, $kind) = @_;
    shift @{$self->setup_order()};
}

sub register_faction {
    my ($self, $faction) = @_;

    my @setup_order = @terra_mystica::factions;
    push @setup_order, reverse @terra_mystica::factions;
    push @setup_order, 'nomads' if $terra_mystica::factions{nomads};

    if ($terra_mystica::factions{chaosmagicians}) {
        @setup_order = grep { $_ ne 'chaosmagicians' } @setup_order;
        push @setup_order, 'chaosmagicians';
    }
    push @setup_order, reverse @terra_mystica::factions;

    $self->setup_order([@setup_order]);
}

## Dealing with the active player.

# Make a faction become the active one
sub start_full_move {
    my ($self, $faction) = @_;
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
sub require_subaction {
    my ($self, $faction, $type, $followup) = @_;
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
        my @unpassed = grep { !$_->{passed} } values %terra_mystica::factions;
        if (@unpassed == 1 or $faction->{planning}) {
            terra_mystica::finish_row($faction);
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
sub allow_pass {
    my ($self, $faction) = @_;
    $faction->{allowed_sub_actions} = {
        pass => 1,
    };    
}

# The player is allowed to build a dwelling without using up a full action.
sub allow_build {
    my ($self, $faction) = @_;
    $faction->{allowed_sub_actions} = {
        build => 1,
    };
}

# Is the faction currently the active one?
sub is_active {
    my ($self, $faction) = @_;

    defined $self->active_faction() and $faction == $self->active_faction();
}

# Name of action currently active, or undef
sub active_faction_name {
    my $self = shift;
    my $faction = $self->active_faction();
    $faction and $faction->{name};
}

## Tracking the set of players

sub add_player {
    my ($self, $player) = @_;
    $player->{index} = $self->player_count();
    push @{$self->players()}, $player;
}

sub player_count {
    my ($self) = @_;
    scalar @{$self->players()};
}

sub correct_player_count {
    my ($self) = @_;

    my $wanted_count = $self->game()->{player_count};
    if (!defined $wanted_count) { return 1 }
    if ($self->player_count() == $wanted_count) { return 1 }

    return 0;
}

## State machine

# What should be done next in the game? Mostly movement between major
# phases of the game.
sub what_next {
    my ($self) = @_;

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
sub advance_state {
    my ($self, $new_state) = @_;
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

sub in_wait_for_players {
    my ($self) = @_;

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

sub in_select_factions {
    my ($self) = @_;

    if (!$self->player_count()) {
        return;
    }

    if ($self->player_count() != @terra_mystica::factions) {
        my $player = $self->players->[@terra_mystica::factions];
        $self->replace_all_actions({
            type => 'faction',
            player => ($player->{displayname} // $player->{name}),
            player_index => "player".(1+@terra_mystica::factions)});
    } else {
        $self->state('initial-dwellings');
    }
}

sub in_initial_dwellings {
    my ($self) = @_;

    if ($self->setup_order_count() <= @terra_mystica::factions) {
        $self->state('initial-bonus');
    } else {
        my $faction_name = $self->setup_order()->[0];
        $self->replace_all_actions(
            {
                type => 'dwelling',
                faction => $faction_name,
            });
        $self->allow_build($terra_mystica::factions{$faction_name});
    }
}

sub in_initial_bonus {
    my ($self) = @_;

    if ($self->setup_order_count()) {
        my $faction_name = $self->setup_order()->[0];
        $self->replace_all_actions(
            {
                type => 'bonus',
                faction => $faction_name,
            });
        $self->allow_pass($terra_mystica::factions{$faction_name});
    } else {
        $self->replace_all_actions();
        $self->game()->{ledger}->finish_row();
        $self->state('income');
    }
}

sub in_income {
    my ($self) = @_;

    if ($self->action_required_count()) {
        return;
    }

    my $income_taken = 0;
    for my $faction (values %terra_mystica::factions) {
        $income_taken ||= $faction->{income_taken};
    }

    if (!$income_taken) {
        terra_mystica::command_income('');
    }

    $self->state('use-income-spades');
}

sub in_use_income_spades {
    my ($self) = @_;

    if ($self->action_required_count()) {
        return;
    }

    $self->game()->{ledger}->finish_row();
    $self->state('play');
    terra_mystica::command_start();
}

sub in_play {
    my ($self) = @_;

    if ($self->action_required_count()) {
        return;
    }

    my $all_passed = 1;
    for my $faction (values %terra_mystica::factions) {
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

sub in_abort {
    my ($self) = @_;

    $self->replace_all_actions({ type => 'gameover', aborted => 1 });
}

1;
