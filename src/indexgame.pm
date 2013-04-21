#!/usr/bin/perl -w

use strict;

use DBI;
use POSIX qw(strftime);

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0, RaiseError => 1});

sub index_game {
    my ($id, $write_id, $game, $timestamp) = @_;

    $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime ($timestamp || time);

    my ($res) = $dbh->do(
        'update game set needs_indexing=?, write_id=?, finished=?, last_update=? where id = ?',
        {},
        0, $write_id, $game->{finished}, $timestamp, $id);
    if ($res == 0) {
        $dbh->do(
            'insert into game (id, write_id, finished, needs_indexing) values (?, ?, ?, false)',
            {},
            $id, $write_id, $game->{finished});
    }

    $dbh->do("delete from game_role where game=?",
             {},
             $id);

    my $pi = 0;
    my @player_roles = map {
        { name => "player".++$pi,
          email => $_->{email} }
    } @{$game->{players}};
    shift @player_roles for 1..(values %{$game->{factions}});

    my @admin_roles = ();
    if ($game->{admin}) {
        push @admin_roles, { name => 'admin', email => $game->{admin}}
    }

    for my $faction (values %{$game->{factions}},
                     @player_roles,
                     @admin_roles) {
        my $action_required = 1*!!(grep {
            ($_->{faction} and $_->{faction} eq $faction->{name}) or
                ($_->{player_index} and $_->{player_index} eq $faction->{name});
        } @{$game->{action_required}});
        ($res) = $dbh->do(
            'update game_role set email=lower(?),action_required=? where game=? and faction=?',
            {},
            $faction->{email}, $action_required, $id, $faction->{name});
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
