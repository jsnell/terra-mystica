#!/usr/bin/perl -lw

use strict;
no indirect;

use DBI;
use Digest::SHA qw(sha1_hex);

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;
use Game::Constants;

my $dbh = get_db_connection;

my ($mapid, $vp_variant, $canal_info) = @ARGV;
die "No game id supplied\n" if !$mapid;
die "No vp variant supplied\n" if !$vp_variant;
die "No canal info supplied\n" if !$canal_info;

if (!$Game::Constants::vp_setups{$vp_variant}) {
    die "Bad vp variant '$vp_variant'\n"
}

if (!$Game::Constants::canal_setups{$canal_info}) {
    die "Bad canal info '$canal_info'\n"
}

my ($map_str) = $dbh->selectrow_array("select terrain from map_variant where id=?", {}, $mapid);
die "Bad map id: '$mapid'" if !$map_str;

my $base_map = [ split /\s+/, $map_str ];

# Not sure if I needed to modify this line.  Provides a new unique ID, but maybe too big (?)
# Don't really know anything about this algorithm.
my $id = sha1_hex "$map_str $vp_variant $canal_info";

$dbh->do("begin");

$dbh->do("insert into map_variant (id, terrain, vp_variant, canal_info) values (?, ?, ?, ?)",
         {},
         $id, $map_str, $vp_variant, $canal_info);

$dbh->do("commit");
