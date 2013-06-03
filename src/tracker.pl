#!/usr/bin/perl -wl

package terra_mystica;

use List::Util qw(max);
use strict;
use JSON;

BEGIN {
    my $target = shift @ARGV;
    unshift @INC, "$target/cgi-bin/";
}

use game;
use tracker;

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}


my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1, RaiseError => 1});

my @rows = get_game_commands $dbh, $ARGV[0];

# @rows = @rows[0..(min $ENV{MAX_ROW}, scalar(@rows)-1)];

my $res = evaluate_game { rows => [ @rows ] };
print_json $res;

if (scalar @{$res->{error}}) {
    print STDERR $_ for @{$res->{error}};
    exit 1;
}

