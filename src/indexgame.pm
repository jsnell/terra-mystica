#!/usr/bin/perl -w

use strict;

use DBI;

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0, RaiseError => 1});

sub index_game {
    my ($id, $write_id, $game) = @_;

    my ($res) = $dbh->do(
        'update game set needs_indexing=?, write_id=?, finished=? where id = ?',
        {},
        0, $write_id, $game->{finished}, $id);
    if ($res == 0) {
        $dbh->do(
            'insert into game (id, write_id, finished, needs_indexing) values (?, ?, ?, false)',
            {},
            $id, $write_id, $game->{finished});
    }

    for my $faction (values %{$game->{factions}},
                     { name => 'admin', email => $game->{admin}}) {
        my $action_required = grep {
            $_->{faction} and $_->{faction} eq $faction->{name}
        } @{$game->{action_required}};
        ($res) = $dbh->do(
            'update game_role set email=lower(?),action_required=? where game=? and faction=?',
            {},
            $faction->{email}, 1*!!$action_required, $id, $faction->{name});
        if ($res == 0) {
            $dbh->do('insert into game_role (game, email, faction, action_required) values (?, lower(?), ?, ?)',
                     {}, $id, $faction->{email}, $faction->{name}, $action_required);
        }
    }

    $dbh->commit(); 
}

END {
    $dbh->disconnect();
}
