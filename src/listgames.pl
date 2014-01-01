#!/usr/bin/perl -wl

package terra_mystica;

use strict;

use JSON;
use List::Util qw(max);
use Time::HiRes qw(time);

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
    my $query = $_;
    chomp $query;
    my $begin = time;
    my $res = get_user_game_list $dbh, split /\s+/, $query;

    $| = 1;
    print_json { res => $res, cost => time - $begin };
}
