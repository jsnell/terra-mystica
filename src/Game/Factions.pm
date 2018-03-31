#!/usr/bin/perl -wl

package Game::Factions;
use Exporter::Easy (EXPORT => [ 'setup_faction', 'factions_conflict' ]);

no indirect qw(fatal);
use strict;

use Method::Signatures::Simple;

use Game::Constants;

sub clone {
    my $data = shift;
    my $ref = ref $data;

    if (!$ref) {
        return $data;
    } elsif ($ref eq 'HASH') {
        return { map { ($_, clone($data->{$_})) } keys %{$data} }
    } elsif ($ref eq 'ARRAY') {
        return [ map { clone($_) } @{$data} ]
    } else {
        die "Don't know how to clone a $ref\n";
    }
};

func initialize_faction($game, $faction_name) {
    my $faction;

    for my $variant (@{$game->{faction_variants}}) {
        $faction //= clone $faction_setups_extra{$variant}{$faction_name};
    }
    $faction //= clone $faction_setups{$faction_name};

    die "Unknown faction: $faction_name\n" if !$faction;

    $faction->{name} = $faction_name;
    $faction->{allowed_actions} = 0;

    $faction->{P} ||= 0;
    $faction->{P1} ||= 0;
    $faction->{P2} ||= 0;
    $faction->{P3} ||= 0;

    my $initial_vp = 20;
    if (defined $game->{vp_setup}{$faction_name}) {
        $initial_vp = $game->{vp_setup}{$faction_name};
    }
    $faction->{VP} = $faction->{vp_source}{initial} = $initial_vp;        
    $faction->{KEY} = 0;

    $faction->{MAX_P} //= 7;

    for (@cults) {
        $faction->{$_} ||= 0;
        $faction->{"MAX_$_"} = 10;
    }
    $faction->{'CULT'} ||= 0;
    $faction->{'CULT_P'} ||= 0;

    my $buildings = $faction->{buildings};
    $buildings->{D}{max_level} = 8;
    $buildings->{TP}{max_level} = 4;
    $buildings->{SH}{max_level} = 1;
    $buildings->{TE}{max_level} = 3;
    $buildings->{SA}{max_level} = 1;

    for (0..2) {
        $buildings->{TE}{advance_gain}[$_]{GAIN_FAVOR} ||= 1;
    }
    $buildings->{SA}{advance_gain}[0]{GAIN_FAVOR} ||= 1;

    for my $building (values %{$buildings}) {
        $building->{level} = 0;
    }

    $faction->{SPADE} = 0;
    $faction->{TOWN_SIZE} = 7;
    $faction->{BRIDGE_COUNT} = 3;
    $faction->{planning} = 0;

    my %base_exchange_rates = (
        PW => { C => 1, W => 3, P => 5 },
        W => { C => 1 },
        P => { C => 1, W => 1 },
        C => { VP => 3 }
    );
    if ($faction->{exchange_rates}) {
        for my $from_key (keys %{$faction->{exchange_rates}}) {
            my $from = $faction->{exchange_rates}{$from_key};
            for my $to_key (keys %{$from}) {
                $base_exchange_rates{$from_key}{$to_key} = $from->{$to_key};
            }
        }
    }
    $faction->{exchange_rates} = { %base_exchange_rates };

    return $faction;
}

func factions_conflict($faction, $other) {
    my $tags = sub {
        my $f = shift;
        map { ($_, 1) } grep { $_ } map { $f->{$_} } qw(color board secondary_color)
    };

    my %faction_tags = $tags->($faction);
    my %other_tags = $tags->($other);

    for (keys %faction_tags) {
        return 1 if $other_tags{$_};
    }

    return 0;
}

func setup_faction($game, $faction_name, $player, $email) {
    my $acting = $game->{acting};

    my $faction = initialize_faction($game, $faction_name);
    my $player_record = {};
    my $players = $acting->players();
    if (@{$players}) {
        $player_record = $players->[$acting->faction_count()];
        if ($player and $player ne $player_record->{name}) {
            die "Expected ".($player_record->{name})." to pick a faction";
        }
        $email ||= $player_record->{email};
        if (!$player) {
            $player = $player_record->{name};
        }
    }

    if (defined $player) {
        $faction->{player} = "$player";
        $faction->{username} = $player_record->{username};
    }

    $faction->{email} = $email;

    for my $other_faction ($acting->factions_in_order(1)) {
        if (factions_conflict($faction, $other_faction)) {
            die "Can't add $faction_name, $other_faction->{name} already in use\n";
        }
    }

    $faction->{start_player} = 1 if !$acting->faction_count();
    $faction->{income_taken} = 0;
    $game->{acting}->register_faction($faction);
    $faction->{start_order} = $acting->faction_count();
}

1;
