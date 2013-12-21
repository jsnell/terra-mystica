#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use List::Util qw(sum max min);

use vars qw(%game);

use acting;
use commands;
use cults;
use ledger;
use map;
use resources;
use scoring;
use tiles;
use towns;

sub finalize {
    my ($delete_email, $faction_info) = @_;

    update_reachable_build_locations;
    update_reachable_tf_locations;
    update_tp_upgrade_costs;
    update_mermaid_town_connections;

    if ($delete_email) {
        for (@{$game{acting}->players()}) {
            delete $_->{email};
        }
    } else {
        my $pi = 0;
        for (@{$game{acting}->players()}) {
            if (!defined $_->{email}) {
                $_->{email} = $faction_info->{"player".++$pi}{email};
            }
        }
    }

    # Delete all "transform" records except the first one (to get the
    # sequencing right during income phase).
    my $spade_seen = 0;
    for (@{$game{acting}->action_required()}) {
        if ($_->{type} eq 'transform') {
            $_ = '' if $spade_seen++;
        }
    }
    $game{acting}->clear_empty_actions();

    # Don't see a point in this. Most likely it was just a diff-reduction
    # attempt. (And now fails due to Readonly-protecting the static data).
    # for my $action (values %actions) {
    #     if ($action->{subaction}) {
    #         delete $action->{subaction}{dig};
    #     }
    # }

    for my $faction ($game{acting}->factions_in_order()) {
        if ($faction->{waiting}) {
            my $action = $game{acting}->action_required()->[0];
            if ($action->{faction} eq $faction->{name}) {
                $faction->{waiting} = 0;
            }
        }
        if ($faction->{planning}) {
            $game{acting}->replace_all_actions(
                {
                    type => 'planning',
                    faction => $faction->{name}
                });
        }
        my $faction_count = $game{acting}->faction_count();
        my $info;
        if (exists $faction_info->{$faction->{name}}) {
            $info = $faction_info->{$faction->{name}};
        } elsif (exists $faction_info->{"player${faction_count}"}) {
            $info = $faction_info->{"player${faction_count}"}
        }
        if (defined $info) {
            $faction->{username} = $info->{username};
            $faction->{email} //= $info->{email};
            $faction->{player} = $info->{displayname};
            $faction->{registered} = 1;
        } else {
            $faction->{registered} = 0;
        }
    }

    for my $faction ($game{acting}->factions_in_order()) {
        $faction->{income} = { faction_income $faction };        
        if ($delete_email) {
            delete $faction->{email};
        }
        if ($game{round} == 6 and !$game{finished}) {
            $faction->{vp_projection} = { faction_vps $faction };
        }
        # delete $faction->{allowed_actions};
        # delete $faction->{allowed_sub_actions};
        # delete $faction->{allowed_build_locations};
        delete $faction->{locations};
        delete $faction->{BRIDGE_COUNT};
        delete $faction->{leech_not_rejected};
        delete $faction->{leech_rejected};
        if ($game{round} == 6) {
            delete $faction->{income};
            delete $faction->{income_breakdown};
        }
        for (values %{$faction->{buildings}}) {
            delete $_->{subactions};
        }
        if ($faction->{waiting}) {
            $game{acting}->dismiss_action($faction, undef);
        }
    }

    for my $hex (values %map) {
        delete $hex->{adjacent};
        delete $hex->{range};
        delete $hex->{bridge};
    }
    
    for my $key (keys %cults) {
        $map{$key} = $cults{$key};
    }

    for my $key (keys %{$game{bonus_coins}}) {
        $map{$key} = $game{bonus_coins}{$key};
    }

    for (qw(BRIDGE TOWN_SIZE GAIN_ACTION carpet_range)) {
        delete $pool{$_};
    }
}

sub evaluate_game {
    my $data = shift;
    my $faction_info = $data->{faction_info};

    local %game = (
        # How many players the game should have. Note that this can be
        # different from how many it has, which you get from
        # acting->player_count()
        player_count => undef,
        round => 0,
        turn => 0,
        aborted => 0,
        finished => 0,
        admin_email => undef,
        options => {},
        leech_id => 0,
        bonus_coins => {},
    );
    $game{ledger} = terra_mystica::Ledger->new({game => \%game});
    $game{acting} = terra_mystica::Acting->new(
        {
            game => \%game,
            players => $data->{players},
        });

    local %map = ();
    local %reverse_map = ();
    local @bridges = ();
    local %pool = ();
    local @score_tiles = ();

    setup_map;

    setup_cults;

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

    if ($game{acting}->player_count()) {
        @command_stream = grep { $_->[1] !~ /^player /i } @command_stream;
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
        order => [ map { $_->{name} } $game{acting}->factions_in_order() ],
        map => \%map,
        actions => \%actions,
        factions => $game{acting}->factions(),
        pool => \%pool,
        bridges => \@bridges,
        ledger => $game{ledger}->flush(),
        error => \@error,
        towns => { map({$_, $tiles{$_}} grep { /^TW/ } keys %tiles ) },
        score_tiles => [ map({$tiles{$_}} @score_tiles ) ],
        bonus_tiles => { map({$_, $tiles{$_}} grep { /^BON/ } keys %tiles ) },
        bonus_coins => $game{bonus_coins},
        favors => { map({$_, $tiles{$_}} grep { /^FAV/ } keys %tiles ) },
        action_required => $game{acting}->action_required(),
        active_faction => $game{acting}->active_faction_name(),
        history_view => $history_view,
        round => $game{round},
        turn => $game{turn},
        finished => $game{finished},
        aborted => $game{aborted},
        cults => \%cults,
        players => $game{acting}->players(),
        player_count => $game{player_count},
        options => $game{options},
        admin => $data->{delete_email} ? '' : $game{admin_email},
    }

}

1;
