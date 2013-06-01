#!/usr/bin/perl -w

use strict;

use DBI;
use File::Slurp qw(read_file);
use File::Basename;

BEGIN { push @INC, dirname $0 }

use indexgame;
use tracker;

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1, RaiseError => 1});

sub evaluate_and_index_game {
    my ($id) = ($_[0] =~ m{([a-zA-Z0-9]+$)}g);
    die "invalid id $_[0]" if !$id;

    die "Manual indexing currently unsupported";

    my @rows = read_file "data/read/$id";
    my $game = terra_mystica::evaluate_game {
        rows => [ @rows ],
        delete_email => 0
    };
    my $write_id = glob "data/write/${id}_*";
    $write_id =~ s{.*/}{};
    my $timestamp = (stat "data/read/$id")[9];
    index_game $dbh, $id, $write_id, $game, $timestamp;
}

$dbh->do('begin');

for (@ARGV) {
    evaluate_and_index_game $_;
}

$dbh->do('commit');
