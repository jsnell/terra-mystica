#!/usr/bin/perl -w

use strict;
no indirect;

BEGIN { push @INC, "$ENV{PWD}/src/"; }

use JSON;
use DB::Connection;
use DB::AddGames;

my $dbh = get_db_connection;
my $desc = decode_json join '', <>;

{
    validate $dbh, $desc;
    print "Validation passed. Really create games [yn]?\n";
    my $query = <STDIN>;
    chomp $query;
    if ($query eq 'y') {
        make_games $dbh, $desc;
    } else {
        print "Canceling\n";
        exit 1;
    }
}
