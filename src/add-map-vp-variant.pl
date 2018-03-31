#!/usr/bin/perl -lw

use strict;
no indirect;

use DBI;
use Digest::SHA qw(sha1_hex);

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;
use Game::Constants;

my $dbh = get_db_connection;

my ($mapid, $vp_variant) = @ARGV;
die "No game id supplied\n" if !$mapid;
die "No vp variant supplied\n" if !$vp_variant;

if (!$Game::Constants::vp_setups{$vp_variant}) {
    die "Bad vp variant '$vp_variant'\n"
}

my ($map_str) = $dbh->selectrow_array("select terrain from map_variant where id=?", {}, $mapid);
die "Bad map id: '$mapid'" if !$map_str;

my $base_map = [ split /\s+/, $map_str ];

my $id = sha1_hex "$map_str $vp_variant";

$dbh->do("begin");

$dbh->do("insert into map_variant (id, terrain, vp_variant) values (?, ?, ?)",
         {},
         $id, $map_str, $vp_variant);

$dbh->do("commit");
