#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use List::Util qw(sum max min);

use vars qw($round $turn $finished @ledger @action_required %leech);

use commands;
use cults;
use factions;
use map;
use resources;
use scoring;
use tiles;
use towns;

sub finalize {
    my ($delete_email, $faction_info) = @_;

    my $spade_seen = 0;

    if ($delete_email) {
        for (@players) {
            delete $_->{email};
        }
    }

    for (@action_required) {
        if ($_->{type} eq 'transform') {
            $_ = '' if $spade_seen++;
        }
    }
    @action_required = grep { $_ } @action_required;

    for my $action (values %actions) {
        if ($action->{subaction}) {
            delete $action->{subaction}{dig};
        }
    }

    for my $faction (values %factions) {
        if ($faction->{waiting}) {
            my $action = $action_required[0];
            if ($action->{faction} eq $faction->{name}) {
                $faction->{waiting} = 0;
            }
        }
        if ($faction->{planning}) {
            @action_required = ({ type => 'planning',
                                  faction => $faction->{name}});
        }
        if (exists $faction_info->{$faction->{name}}) {
            $faction->{username} = $faction_info->{$faction->{name}}{username};
            $faction->{player} = $faction_info->{$faction->{name}}{displayname};
            $faction->{registered} = 1;
        } else {
            $faction->{registered} = 0;
        }
    }

    for my $faction_name (@factions) {
        my $faction = $factions{$faction_name};
        next if !$faction;
        $faction->{income} = { faction_income $faction->{name} };        
        if ($delete_email) {
            delete $faction->{email};
        }
        if ($round == 6 and !$finished) {
            $faction->{vp_projection} = { faction_vps $faction };
        }
        # delete $faction->{allowed_actions};
        # delete $faction->{allowed_sub_actions};
        # delete $faction->{allowed_build_locations};
        delete $faction->{locations};
        delete $faction->{BRIDGE_COUNT};
        delete $faction->{leech_not_rejected};
        if ($round == 6) {
            delete $faction->{income};
            delete $faction->{income_breakdown};
        }
        for (values %{$faction->{buildings}}) {
            delete $_->{subactions};
        }
        if ($faction->{waiting}) {
            @action_required = grep {
                $_->{faction} ne $faction_name;
            } @action_required;
        }
    }
        
    if ($round > 0) {
        for (0..($round-2)) {
            $tiles{$score_tiles[$_]}->{old} = 1;
        }
        
        current_score_tile->{active} = 1;
    }

    if (@score_tiles) {
        $tiles{$score_tiles[-1]}->{income_display} = '';
    }

    for my $hex (values %map) {
        delete $hex->{adjacent};
        delete $hex->{range};
        delete $hex->{bridge};
    }
    
    for my $key (keys %cults) {
        $map{$key} = $cults{$key};
    }

    for my $key (keys %bonus_coins) {
        $map{$key} = $bonus_coins{$key};
        $tiles{$key}{bonus_coins} = $bonus_coins{$key};
    }

    for (qw(BRIDGE TOWN_SIZE GAIN_ACTION carpet_range)) {
        delete $pool{$_};
    }
}

sub evaluate_game {
    local @setup_order = ();
    local %map = ();
    local %reverse_map = ();
    local @bridges = ();
    local %pool = ();
    local %bonus_coins = ();
    local %leech = ();
    local $leech_id = 0;
    local @action_required = ();
    local @ledger = ();
    local $round = 0;
    local $turn = 0;
    local $finished = 0;
    local @score_tiles = ();
    local %factions = ();
    local %factions_by_color = ();
    local @factions = ();
    local @setup_order = ();
    local @players = ();
    local $admin_email = '';
    local %options = ();
    local $active_faction = '';

    setup_map;

    setup_cults;

    my $data = shift;
    my $faction_info = $data->{players};
    my $row = 1;
    my @error = ();
    my $history_view = 0;

    my @command_stream = ();

    for (@{$data->{rows}}) {
        eval { push @command_stream, clean_commands $_ };
        if ($@) {
            chomp;
            push @error, "Error on line $row [$_]:";
            push @error, "$@\n";
            last;
        }
        $row++;
    }

    @command_stream = rewrite_stream @command_stream;

    if (!@error) {
        eval {
            $history_view = play \@command_stream, $data->{max_row} // 0;
            if ($history_view) {
                push @error, "Showing historical game state (up to row $history_view)";
            }
        }; if ($@) {
            push @error, "$@\n";
        }
    }

    maybe_setup_pool;
    finalize $data->{delete_email} // 1, $faction_info // {};

    return {
        order => \@factions,
        map => \%map,
        actions => \%actions,
        factions => \%factions,
        pool => \%pool,
        bridges => \@bridges,
        ledger => \@ledger,
        error => \@error,
        towns => { map({$_, $tiles{$_}} grep { /^TW/ } keys %tiles ) },
        score_tiles => [ map({$tiles{$_}} @score_tiles ) ],
        bonus_tiles => { map({$_, $tiles{$_}} grep { /^BON/ } keys %tiles ) },
        favors => { map({$_, $tiles{$_}} grep { /^FAV/ } keys %tiles ) },
        action_required => \@action_required,
        active_faction => $active_faction,
        history_view => $history_view,
        round => $round,
        turn => $turn,
        finished => $finished,
        cults => \%cults,
        players => \@players,
        options => \%options,
        admin => $data->{delete_email} ? '' : $admin_email,
    }

}

1;
