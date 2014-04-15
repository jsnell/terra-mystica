#!/usr/bin/perl -wl

use strict;

use JSON;
use POSIX;

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;

use Analyze::ELO;
use Analyze::RatingData;

my $dbh = get_db_connection;
my $rating_data = read_rating_data $dbh;
my $elo = compute_elo $rating_data;

# pprint_elo_results $elo;

$elo->{timestamp} = POSIX::strftime "%Y-%m-%d %H:%M UTC", gmtime time;

$dbh = get_db_connection;
$dbh->do("begin");
$dbh->do("delete from player_ratings");
for my $player (keys %{$elo->{players}}) {
    my $rating = $elo->{players}{$player}{score};
    $dbh->do("insert into player_ratings (player, rating) values (?, ?)",
             {},
             $player, int $rating);
}
$dbh->do("commit");

print encode_json $elo;

