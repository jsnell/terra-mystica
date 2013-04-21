#!/usr/bin/perl -w

use strict;

use File::Slurp qw(read_file);
use File::Basename;

BEGIN { push @INC, dirname $0 }

use indexgame;
use tracker;

sub evaluate_and_index_game {
    my ($id) = ($_[0] =~ m{([a-zA-Z0-9]+$)}g);
    die "invalid id $_[0]" if !$id;
    my @rows = read_file "data/read/$id";
    my $game = terra_mystica::evaluate_game {
        rows => [ @rows ],
        delete_email => 0
    };
    my $write_id = glob "data/write/${id}_*";
    $write_id =~ s{.*/}{};
    my $timestamp = (stat "data/read/$id")[9];
    index_game $id, $write_id, $game, $timestamp;
}

for (@ARGV) {
    evaluate_and_index_game $_;
}
