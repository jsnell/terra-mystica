#!/usr/bin/perl -wl

package Analyze::RatingData;
use Exporter::Easy (EXPORT => ['read_rating_data']);

use strict;

use DB::Game;

sub faction_key {
    my ($faction, $map) = @_;
    $map //= '126fe960806d587c78546b30f1a90853b1ada468';

    return "$faction $map";
}

sub handle_game {
    my ($res, $output, $players, $factions, $maps) = @_;

    my $faction_count = keys %{$res->{factions}};
    return if $faction_count < 3;

    my %player_ids = (); 
    for (values %{$res->{factions}}) {
        next if !$_->{id_hash};
        if ($player_ids{$_->{id_hash}}++) {
            return;
        }
    }

    # for (values %{$res->{factions}}) {
    #     if ($_->{username} and $_->{username} eq 'jsnell') {
    #         $_->{vp} += 1;
    #     }
    # }
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
        $f->{fkey} = faction_key $f->{faction}, $f->{base_map};
        $factions->{$f->{fkey}}{games}++;
        $players->{$f->{id_hash}}{username} = $f->{username};
        $players->{$f->{id_hash}}{games}++;
    }

    for my $i (0..$#f) {
        my $f1 = $f[$i];

        for my $j (($i+1)..$#factions) {
            my $f2 = $f[$j];
            next if $f1->{id_hash} eq 'unknown';
            next if $f2->{id_hash} eq 'unknown';
            my $record = {
                a => {
                    username => $f1->{username},
                    id_hash => $f1->{id_hash},
                    faction => $f1->{faction},
                    fkey => $f1->{fkey},
                    vp => $f1->{vp},
                    dropped => $f1->{dropped}
                },
                b => {
                    username => $f2->{username},
                    id_hash => $f2->{id_hash},
                    faction => $f2->{faction},
                    fkey => $f2->{fkey},
                    vp => $f2->{vp},
                    dropped => $f2->{dropped}
                },
                last_update => $res->{last_update},
                id => $res->{id},
            };
            push @{$output}, $record;
        }
    }
}

sub read_rating_data {
    my ($dbh, $filter, $params) = @_;
    my @output = ();
    my %players = ();
    my %factions = ();

    my %results = get_finished_game_results $dbh, '', %{$params};
    my %games = ();
    my %faction_count = ();
    my @exclude_factions = qw(riverwalkers
                              riverwalkers_v4
                              shapeshifters
                              shapeshifters_v2
                              shapeshifters_v3
                              shapeshifters_v4);

    for (@{$results{results}}) {
        next if $filter and !$filter->($_);

        next if $_->{faction} =~ /^(nofaction|player)/;
        
        my @ss_opt = map /variable_(v2|v3|v4|v5)/g, @{$_->{options}};
        if (@ss_opt and $_->{faction} eq 'shapeshifters') {
            $_->{faction} = "shapeshifters_@{ss_opt}";
        }

        my @rw_opt = map /variable_(v4|v5)/g, @{$_->{options}};
        if (@rw_opt and $_->{faction} eq 'riverwalkers') {
            $_->{faction} = "riverwalkers_@{rw_opt}";
        }

        $games{$_->{game}}{factions}{$_->{faction}} = $_;
        $games{$_->{game}}{id} = $_->{game};
        $games{$_->{game}}{last_update} = $_->{last_update};
        $games{$_->{game}}{base_map} = $_->{base_map};
        $faction_count{$_->{faction}}++;
    }

    for (values %games) {
        my $ok = 1;
        # if (!$filter) {
        #     for (keys %{$_->{factions}}) {
        #         # Don't include games with new factions in ratings
        #         # until there's at least a bit of data.
        #         $ok = 0 if $faction_count{$_} < 50;
        #     }
        # }
        for my $f (@exclude_factions) {
            if (exists $_->{factions}{$f}) {
                $ok = 0;
            }
        }

        if ($ok) {
            handle_game $_, \@output, \%players, \%factions;
        } else {
            delete $games{$_->{id}};
        }
    }

    return {
        players => \%players,
        factions => \%factions,
        games => \%games,
        results => \@output 
    };
}

1;

