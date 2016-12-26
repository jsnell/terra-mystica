#!/usr/bin/perl -lw

package terra_mystica;

use strict;

use DBI;
use Digest::SHA qw(sha1_hex);
use JSON;
use POSIX;
use File::Basename qw(dirname);
use List::Util qw(sum);

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use Analyze::RatingData;
use DB::Connection;
use DB::Game;
use tracker;

my $dbh = get_db_connection;

my $results = read_rating_data $dbh, sub {
    my $res = shift;

    return 0 if $res->{player_count} != 4;
    
    # return 0 if sha1_hex($res->{game}) !~ /^f0/;
    $res->{base_map} //= '126fe960806d587c78546b30f1a90853b1ada468'; 
    # return 0 if !defined $res->{base_map};
    
    # return 0 if ($res->{base_map} // '') ne 'c07f36f9e050992d2daf6d44af2bc51dca719c46';

    return 1;
}, { include_unranked => 1};

for my $id (keys %{$results->{games}}) {
    my $game = $results->{games}{$id};
    my @rows = get_game_commands $dbh, $id;
    my @command_stream = ();

    my $row = 0;
    for (@rows) {
        eval { push @command_stream, clean_commands $_ };
        if ($@) {
            chomp;
            print STDERR "Error on line $row [$_]:";
            print STDERR "$@\n";
            last;
        }
        $row++;
    }

    my %record = ();
    $record{id} = $id;

    for my $row (@command_stream) {
        my $faction = $row->[0];
        next if !$faction;
        next if $faction eq 'comment';
        if ($faction eq 'riverwalkers' or $faction eq 'shapeshifters') {
            $faction .= "_v5";
        }
        while ($row->[1] =~ /^build (\S+)/gi) {
            push @{$record{factions}{$faction}{builds}}, $1;
        }
    }

    for my $faction (keys %{$game->{factions}}) {
        for my $key (qw(vp rank)) {
            $record{factions}{$faction}{$key} = $game->{factions}{$faction}{$key};
        }
    }

    print encode_json \%record;
}
