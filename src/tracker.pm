#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use List::Util qw(sum max min);

use vars qw(%game);

use Game::Constants;
use Game::Events;

use acting;
use commands;
use cults;
use ledger;
use map;
use resources;
use scoring;
use towns;

sub finalize {
    my ($delete_email, $faction_info, $errors) = @_;

    if (!$errors) {
        update_reachable_build_locations;
        update_reachable_tf_locations;
        update_tp_upgrade_costs;
        update_mermaid_town_connections;
    }

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

    $game{acting}->clear_empty_actions();
    if (defined $game{metadata}{chess_clock_hours_initial} and
        defined $game{metadata}{chess_clock_hours_per_round}) {
        $game{current_chess_clock_hours} =
            $game{metadata}{chess_clock_hours_initial} +
            $game{metadata}{chess_clock_hours_per_round} * $game{round};
    }

    # Delete all "transform" records except the first one (to get the
    # sequencing right during income phase).
    my $spade_seen = 0;
    for (@{$game{acting}->action_required()}) {
        if ($_->{type} eq 'transform' or
            $_->{type} eq 'unlock-terrain') {
            $_ = '' if $spade_seen++;
        }
    }
    $game{acting}->clear_empty_actions();
    my %faction_info_usernames = map { $faction_info->{$_}->{username} => $_ } keys %{$faction_info};

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
        my $player_index = $faction->{username} ? $faction_info_usernames{$faction->{username}} : undef;
        my $info;
        if (exists $faction_info->{$faction->{name}}) {
            $info = $faction_info->{$faction->{name}};
        } elsif (defined $player_index and
                 exists $faction_info->{$player_index}) {
            $info = $faction_info->{$player_index};
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
        if ($delete_email) {
            delete $faction->{email};
        }
        next if $faction->{dummy};

        $faction->{income} = (faction_income $faction)->{total};
        if ($game{round} == 6 and !$game{finished}) {
            $faction->{vp_projection} = { faction_vps $faction };
        }
        delete $faction->{locations};
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
        delete $faction->{TF_NEED_HEX_ADJACENCY};
        if (exists $faction->{special}) {
            delete $faction->{special}{mode};
        }
        delete $faction->{building_strength};

        for my $cult (@cults) {
            delete $faction->{cult_blocked};
        }
    }

    for my $hex (values %map) {
        delete $hex->{adjacent};
        delete $hex->{range};
        delete $hex->{bridge};
        delete $hex->{edge};
        if ($hex->{town}) {
            $hex->{town} = 1;
        }
    }

    # Gross, but still needed
    for my $key (keys %{$game{cults}}) {
        $map{$key} = $game{cults}{$key};
    }

    # Obsolete in .js, just retained for diffs
    for my $key (keys %{$game{bonus_coins}}) {
        $map{$key} = $game{bonus_coins}{$key};
    }

    for (qw(BRIDGE TOWN_SIZE GAIN_ACTION TF_NEED_HEX_ADJACENCY carpet_range
            LOSE_CULT LOSE_PW_TOKEN VOLCANO_TF CULTS_ON_SAME_TRACK)) {
        delete $game{pool}{$_};
    }
}

sub evaluate_game {
    my $data = shift;
    my $faction_info = $data->{faction_info};
    my $metadata = $data->{metadata};    

    local %game = (
        # How many players the game should have. Note that this can be
        # different from how many it has, which you get from
        # acting->player_count()
        player_count => undef,
        round => 0,
        turn => 0,
        aborted => 0,
        finished => 0,
        options => {
            map { ($_, 1) } @{$metadata->{game_options}}
        },
        leech_id => 0,
        bonus_coins => {},
        pool => undef,
        cults => setup_cults,
        bridges => [],
        score_tiles => [],
        preview_warnings => [],
        metadata => $metadata,
        base_map => ($metadata->{base_map} or \@base_map),
        map_variant => $metadata->{map_variant},
        faction_variants => [],
        final_scoring => { map { $_ => $final_scoring{$_} } qw(network cults) },
    );
    $game{ledger} = terra_mystica::Ledger->new({game => \%game});
    $game{acting} = terra_mystica::Acting->new(
        {
            game => \%game,
            players => $data->{players},
        });
    $game{events} = Game::Events->new({game => \%game});

    if (defined $game{metadata}{vp_variant}) {
        $game{vp_setup} = $Game::Constants::vp_setups{
            $game{metadata}{vp_variant}};
    }

    local %map = %{setup_map $game{base_map}};

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

    if ($metadata->{aborted}) {
        $game{acting}->advance_state('abort');
    }

    maybe_setup_pool;
    finalize $data->{delete_email} // 1, $faction_info // {}, scalar @error;

    my $ret = {
        order => [ map { $_->{name} } $game{acting}->factions_in_order() ],
        map => \%map,
        actions => \%actions,
        factions => $game{acting}->factions(),
        pool => $game{pool},
        bridges => $game{bridges},
        ledger => $game{ledger}->flush(),
        error => \@error,
        towns => { map({$_, $tiles{$_}} grep { /^TW/ } keys %tiles ) },
        score_tiles => [ map({$tiles{$_}} @{$game{score_tiles}} ) ],
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
        cults => $game{cults},
        players => $game{acting}->players(),
        player_count => $game{player_count},
        options => $game{options},
        map_variant => $game{map_variant},
        final_scoring => $game{final_scoring},
        final_scoring_help => $game{final_scoring_help},
        non_standard => $game{non_standard},
        dodgy_resource_manipulation => $game{dodgy_resource_manipulation},
        events => $game{events}->data(),
        preview_warnings => $game{preview_warnings},
        current_chess_clock_hours => $game{current_chess_clock_hours},
        vp_setup => $game{vp_setup},
        available_factions => {
            map({ ($_, 1) }
                keys %faction_setups,
                map { keys %{$faction_setups_extra{$_}} } @{$game{faction_variants}})
        },                
    };

    %game = ();
    
    $ret;
}

1;
