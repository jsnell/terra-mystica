#!/usr/bin/perl -wl

package terra_mystica;

use List::Util qw(max);
use strict;
use JSON;

BEGIN {
    my $target = shift @ARGV;
    unshift @INC, "$target/cgi-bin/";
}

use db;
use game;
use tracker;

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}


my $dbh = get_db_connection;

my $id = $ARGV[0];
my @rows = get_game_commands $dbh, $id;

# @rows = @rows[0..(min $ENV{MAX_ROW}, scalar(@rows)-1)];

my $res = evaluate_game {
    rows => [ @rows ],
    faction_info => get_game_factions($dbh, $id),
    players => get_game_players($dbh, $id),
};
print_json $res;

if (scalar @{$res->{error}}) {
    print STDERR $_ for @{$res->{error}};
    exit 1;
}

