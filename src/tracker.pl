#!/usr/bin/perl -wl

package terra_mystica;

use List::Util qw(max);
use strict;
use JSON;

our $target;

BEGIN {
    $target = shift @ARGV;
    unshift @INC, "$target/lib/";
}

use tracker;

BEGIN {
    eval {
        require 'db.pm';
        require 'game.pm';
    }; if ($@) {
        require 'DB/Connection.pm';
        DB::Connection->import();
        require 'DB/Game.pm';    
        DB::Game->import();
    }
}

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}


my $dbh = get_db_connection;

while (<>) {
    my $id = $_;
    chomp $id;
    my @rows = get_game_commands $dbh, $id;

# @rows = @rows[0..(min $ENV{MAX_ROW}, scalar(@rows)-1)];

    my $res = evaluate_game {
        rows => [ @rows ],
        faction_info => get_game_factions($dbh, $id),
        players => get_game_players($dbh, $id),
    };
    $| = 1;
    print_json $res;
    if (@{$res->{error}}) {
        print STDERR "$target $id: ERROR: $_" for @{$res->{error}};
    }
}

