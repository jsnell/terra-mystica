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
    my $delete_email = shift;

    my $spade_seen = 0;

    for (@action_required) {
        if ($_->{type} eq 'transform') {
            $_ = '' if $spade_seen++;
        }
    }
    @action_required = grep { $_ } @action_required;

    for my $faction (@factions) {
        $factions{$faction}{income} = { faction_income $faction };        
        if ($delete_email) {
            delete $factions{$faction}{email};
        }
        if ($round == 6 and !$finished) {
            $factions{$faction}{vp_projection} = { faction_vps $factions{$faction} };
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
        delete $hex->{bridgable};
    }
    
    for my $faction (@factions) {
        delete $factions{$faction}{locations};
        delete $factions{$faction}{teleport};
        if ($round == 6) {
            delete $factions{$faction}{income};
            delete $factions{$faction}{income_breakdown};
        }
    }

    for my $key (keys %cults) {
        $map{$key} = $cults{$key};
    }

    for my $key (keys %bonus_coins) {
        $map{$key} = $bonus_coins{$key};
        $tiles{$key}{bonus_coins} = $bonus_coins{$key};
    }

    for (qw(BRIDGE TOWN_SIZE)) {
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
    local $email = '';
    local $admin_email = '';

    setup_map;
    setup_pool;
    setup_cults;

    my $data = shift;
    my $row = 1;
    my @error = ();
    my $history_view = 0;

    for (@{$data->{rows}}) {
        eval { handle_row $_ };
        if ($@) {
            chomp;
            push @error, "Error on line $row [$_]:";
            push @error, "$@\n";
            last;
        }
        $row++;

        if (defined $data->{max_row} and $data->{max_row}) {
            my $max = $data->{max_row};
            if (@ledger >= ($max -1)) {
                push @error, "Showing historical game state (up to row $max)";
                $history_view = @ledger;
                last;
            }
        }
    }

    finalize $data->{delete_email} // 1;

    return {
        order => \@factions,
        map => \%map,
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
        history_view => $history_view,
        round => $round,
        turn => $turn,
        finished => $finished,
        cults => \%cults,
        admin => $data->{delete_email} ? '' : $admin_email,
    }

}

1;
