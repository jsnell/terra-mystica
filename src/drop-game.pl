#!/usr/bin/perl -lw

use strict;
no indirect;

use DBI;

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use DB::Connection;

my $dbh = get_db_connection;

$dbh->do("begin");

my $id = shift;
die "No game id supplied" if !defined  $id;

print $dbh->do("delete from game_options where game=?", {}, $id);
print $dbh->do("delete from game_role where game=?", {}, $id);
print $dbh->do("delete from game_player where game=?", {}, $id);
print $dbh->do("delete from game where id=?", {}, $id);

$dbh->do("commit");
