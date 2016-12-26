#!/usr/bin/perl -lw

package terra_mystica;

use JSON;
no indirect;

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;
use DB::Game;
use tracker;

my $dbh = get_db_connection;

my %by_map = ();

while (<>) {
    my $game = decode_json $_;
    my $metadata = get_game_metadata $dbh, $game->{id};
    my $by_map = ($by_map{$metadata->{map_variant} // '126fe960806d587c78546b30f1a90853b1ada468'} //= {});
    if (!defined $by_map->{base_map}) {
        $by_map->{base_map} = setup_map $metadata->{base_map} || \@base_map;
    }
    for my $faction (keys %{$game->{factions}}) {
        my $by_faction = ($by_map->{factions}{$faction} //= {});
        my $rank = $game->{factions}{$faction}{rank};
        if (!defined $rank) {
            print STDERR "$faction ", encode_json $game;
        }
        for my $build (@{$game->{factions}{$faction}{builds}}) {
            $by_faction->{all}{build}{uc $build}++;
            $by_faction->{$rank}{build}{uc $build}++;
        }
        $by_faction->{all}{games}++;
        $by_faction->{$rank}{games}++;
    }
}

print encode_json \%by_map;
