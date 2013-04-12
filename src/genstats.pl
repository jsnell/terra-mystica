#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use JSON;
use POSIX;
use File::Basename qw(dirname);

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use tracker;

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

my %stats = ();

sub handle_game {
    my $res = shift;

    return if !$res->{finished};

    my $pos = 0;
    my $win_vp = 0;
    for (sort { $b->{VP} <=> $a->{VP} } values %{$res->{factions}}) {
        $pos++;
        my $stat = ($stats{factions}{$_->{name}} ||= {
            wins => 0,
            games_won => [],
        });
        $stat->{count}++;
        if ($pos == 1) {
            $stat->{wins}++;
            push @{$stat->{games_won}}, $res->{id}; 
        }
        $stat->{average_vp} += $_->{VP};
        $stat->{average_position} += $pos;
    }
}

for my $game (@ARGV) {
    local @ARGV = $game;
    my ($id) = ($game =~ m{/([a-zA-Z0-9]+$)}g);
    my @rows = <>;
    my $res = evaluate_game { rows => [ @rows ] };
    $res->{id} = $id;
    handle_game $res;
}

for my $stat (values %{$stats{factions}}) {
    $stat->{win_rate} = int(100 * $stat->{wins} / $stat->{count});
    $stat->{average_vp} = sprintf "%5.2f", $stat->{average_vp} / $stat->{count};
    $stat->{average_position} = sprintf "%5.2f", $stat->{average_position} / $stat->{count};
}

$stats{timestamp} = POSIX::strftime "%Y-%m-%d %H:%M UTC", gmtime time;

print_json { %stats };
