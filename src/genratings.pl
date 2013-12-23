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

print encode_json $elo;

