#!/usr/bin/perl -wl

package Analyze::RatingData;
use Exporter::Easy (EXPORT => ['read_rating_data']);

use strict;

use DB::Game;

sub handle_game {
    my ($res, $output, $players, $factions) = @_;

    my $faction_count = keys %{$res->{factions}};
    return if $faction_count < 3;

    my %player_ids = (); 
    for (values %{$res->{factions}}) {
        next if !$_->{id_hash};
        if ($player_ids{$_->{id_hash}}++) {
            return;
        }
    }

    for (keys %{$res->{factions}}) {
        # $res->{factions}{$_}{vp} += ($adjust{$_} // 0);
    }
    my @f = sort { $b->{vp} <=> $a->{vp} } values %{$res->{factions}};
    my $r = 0;
    for (@f) {
        $_->{rank} = ++$r;
    }

    # Filter out games with no players with an email address
    if (!keys %player_ids) {
        # Whitelist some old PBF games, etc.
        my %whitelist = map { ($_, 1 ) } qw(
            0627puyo
            10
            17
            19
            20
            23
            24
            26
            27
            5
            8
            9
            BlaGame11
            BlaGame8
            IBGPBF5
            Noerrorpls
            gamecepet
            gareth2
            nyobagame
            pbc1
            pbc2
            pbc3
            skelly1
            skelly1a
            skelly1b
            skelly1c
            skelly1d
            skelly1e
            skelly1f
            verandi1
            verandi2
        );
        if (!$whitelist{$res->{id}}) {
            return;
        }
    }

    my @factions = values %{$res->{factions}};
    for my $f (@factions) {
        $f->{id_hash} //= 'unknown';
        $f->{username} //= "unregistered-$f->{id_hash}";
        # $f->{faction} .= "_$faction_count";
        $factions->{$f->{faction}}{games}++;
        $players->{$f->{id_hash}}{username} = $f->{username};
        $players->{$f->{id_hash}}{games}++;
    }

    for my $i (0..$#factions) {
        my $f1 = $factions[$i];

        for my $j (($i+1)..$#factions) {
            my $f2 = $factions[$j];
            next if $f1->{id_hash} eq 'unknown';
            next if $f2->{id_hash} eq 'unknown';
            my $record = {
                a => { id_hash => $f1->{id_hash}, faction => $f1->{faction}, vp => $f1->{vp} },
                b => { id_hash => $f2->{id_hash}, faction => $f2->{faction}, vp => $f2->{vp} },
                last_update => $res->{last_update},
                id => $res->{id},
            };
            push @{$output}, $record;
        }
    }
}

sub read_rating_data {
    my ($dbh) = @_;
    my @output = ();
    my %players = ();
    my %factions = ();

    my %results = get_finished_game_results $dbh, '';
    my %games = ();

    for (@{$results{results}}) {
        $games{$_->{game}}{factions}{$_->{faction}} = $_;
        $games{$_->{game}}{id} = $_->{game};
        $games{$_->{game}}{last_update} = $_->{last_update};
    }

    for (values %games) {
        handle_game $_, \@output, \%players, \%factions;
    }

    return {
        players => \%players,
        factions => \%factions,
        results => \@output 
    };
}

1;

