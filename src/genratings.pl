#!/usr/bin/perl -wl

use strict;

use JSON;
use POSIX;

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use elo;
use rating_data;

my $rating_data = read_rating_data;
my $elo = compute_elo $rating_data;

# pprint_elo_results $elo;

$elo->{timestamp} = POSIX::strftime "%Y-%m-%d %H:%M UTC", gmtime time;

print encode_json $elo;

