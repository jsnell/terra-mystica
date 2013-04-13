#!/usr/bin/perl -w

use strict;

use DBI;

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0, RaiseError => 1});

sub index_game {
    my ($id, $write_id, $game) = @_;

    my ($res) = $dbh->do('update game set needs_indexing = ?, write_id = ? where id = ?',
                         {},
                         0,
                         $write_id, $id);
    if ($res == 0) {
        $dbh->do('insert into game (id, write_id, needs_indexing) values (?, ?, false)', {}, $id, $write_id);
    }

    for my $faction (values %{$game->{factions}},
                     { name => 'admin', email => $game->{admin}}) {
        ($res) = $dbh->do("update game_role set email = ? where game = ? and faction = ?",
                          {},
                          $faction->{email}, $id, $faction->{name});
        if ($res == 0) {
            $dbh->do('insert into game_role (game, email, faction) values (?, ?, ?)',
                     {}, $id, $faction->{email}, $faction->{name});
        }
    }

    $dbh->commit(); 
}
