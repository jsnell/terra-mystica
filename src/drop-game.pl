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

print "Events ", $dbh->do("delete from game_events where game=?", {}, $id);
print "Notes ", $dbh->do("delete from game_note where game=?", {}, $id);
print "Chat metadata ", $dbh->do("delete from chat_read where game=?", {}, $id);
print "Chat messages ", $dbh->do("delete from chat_message where game=?", {}, $id);
print "Game options ", $dbh->do("delete from game_options where game=?", {}, $id);
print "Game roles ", $dbh->do("delete from game_role where game=?", {}, $id);
print "Game players ", $dbh->do("delete from game_player where game=?", {}, $id);
print "Game ", $dbh->do("delete from game where id=?", {}, $id);

my $response;

do {
    print("ok [yn]?");
    $response = <>;
    chomp $response;
} until $response =~ /^[yn]$/;

if ($response eq 'y') {
    $dbh->do("commit");
} else {
    print "Aborting.";
}
