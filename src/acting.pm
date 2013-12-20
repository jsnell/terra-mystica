# Code for tracking what should be happening next in the game.
# Whose turn is it now, what can they do, what can other people do, etc.

package terra_mystica::Acting;
use Mouse;

# Who is playing in this game?
has 'players' => (is => 'rw');

# Which faction is currently acting (a full action, not just a
# async decision on resources).
has 'active_faction' => (is => 'rw');

# What state is the game currently in.
has 'state' => (is => 'rw',
                default => 'wait-for-players');

# Main game data structure
has 'game' => (is => 'rw');

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
            @terra_mystica::action_required = (
                { type => 'not-started',
                  player_count => $player_count,
                  wanted_player_count => $wanted_count }
                );
        }
    } else {
        @terra_mystica::action_required = ();
    }
}

sub in_select_factions {
    my ($self) = @_;

    if (!$self->player_count()) {
        return;
    }

    if ($self->player_count() != @terra_mystica::factions) {
        my $player = $self->players->[@terra_mystica::factions];
        @terra_mystica::action_required = ({
            type => 'faction',
            player => ($player->{displayname} // $player->{name}),
            player_index => "player".(1+@terra_mystica::factions),
                            });
    } else {
        $self->state('initial-dwellings');
    }
}

sub in_initial_dwellings {
    my ($self) = @_;

    if (@terra_mystica::setup_order <= @terra_mystica::factions) {
        $self->state('initial-bonus');
    } else {
        @terra_mystica::action_required = (
            {
                type => 'dwelling',
                faction => $terra_mystica::setup_order[0],
            });
        terra_mystica::allow_build($terra_mystica::factions{$terra_mystica::setup_order[0]});
    }
}

sub in_initial_bonus {
    my ($self) = @_;

    if (@terra_mystica::setup_order) {
        terra_mystica::allow_pass($terra_mystica::factions{$terra_mystica::setup_order[0]});
        @terra_mystica::action_required = (
            {
                type => 'bonus',
                faction => $terra_mystica::setup_order[0],
            });
    } else {
        @terra_mystica::action_required = ();
        $self->game()->{ledger}->finish_row();
        $self->state('income');
    }
}

sub in_income {
    my ($self) = @_;

    if (@terra_mystica::action_required) {
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

    if (@terra_mystica::action_required) {
        return;
    }

    $self->game()->{ledger}->finish_row();
    $self->state('play');
    terra_mystica::command_start();
}

sub in_play {
    my ($self) = @_;

    if (@terra_mystica::action_required) {
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

    @terra_mystica::action_required = ( { type => 'gameover' } );
}

1;
