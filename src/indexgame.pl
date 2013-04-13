#!/usr/bin/perl -w

use strict;

use DBI;
use File::Slurp qw(read_file);
use File::Basename;

BEGIN { push @INC, dirname $0 }

use tracker;

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0, RaiseError => 1});

sub handle_game {
    my ($game) = @_;

    my ($res) = $dbh->do('update game set needs_indexing = ?, write_id = ? where id = ?',
                         {},
                         0,
                         $game->{write_id}, $game->{id});
    if ($res == 0) {
        $dbh->do('insert into game (id, write_id, needs_indexing) values (?, ?, false)', {}, $game->{id}, $game->{write_id});
    }

    for my $faction (values %{$game->{factions}}) {
        ($res) = $dbh->do("update game_role set email = ? where game = ? and faction = ?",
                          {},
                          $faction->{email}, $game->{id}, $faction->{name});
        if ($res == 0) {
            $dbh->do('insert into game_role (game, email, faction) values (?, ?, ?)',
                     {}, $game->{id}, $faction->{email}, $faction->{name});
        }
    }

    $dbh->commit(); 
}

sub index_game {
    my ($id) = ($_[0] =~ m{([a-zA-Z0-9]+$)}g);
    die "invalid id $_[0]" if !$id;
    my @rows = read_file "data/read/$id";
    my $game = terra_mystica::evaluate_game {
        rows => [ @rows ],
        delete_email => 0
    };
    $game->{id} = $id;
    $game->{write_id} = glob "data/write/${id}_*";
    $game->{write_id} =~ s{.*/}{};
    handle_game $game;
}

for (@ARGV) {
    index_game $_;
}

$dbh->disconnect();
