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
        0, $write_id, 1*(!!$game->{finished}), $timestamp, $id);
    if ($res == 0) {
        $dbh->do(
            'insert into game (id, write_id, finished, needs_indexing) values (?, ?, ?, false)',
            {},
            $id, $write_id, 1*(!!$game->{finished}));
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

    if ($game->{finished}) {
        my @by_vp = sort { $b->{VP} <=> $a->{VP} } values %{$game->{factions}};
        my $pos = 0;
        my $prev;
        
        for (@by_vp) {
            $pos++;
            if ($prev and $prev->{VP} == $_->{VP}) {
                $_->{rank} = $prev->{rank};
            } else {
                $_->{rank} = $pos;
            }
        }
    }

    {
        my $pos = 0;
        for (@{$game->{order}}) {
            $game->{factions}{$_}{start_order} = ++$pos;
        }
    }

    for my $faction (values %{$game->{factions}},
                     @player_roles,
                     @admin_roles) {
        my $action_required = 0;
        my $leech_required = 0;

        for my $action (@{$game->{action_required}}) {
            next if $faction->{name} ne $action->{faction};
            if ($action->{type} eq 'leech') {
                $leech_required = 1;
            } else {
                $action_required = 1;
            }
        } 

        $dbh->do('insert into game_role (game, email, faction, action_required, leech_required, vp, rank, start_order) values (?, lower(?), ?, ?, ?, ?, ?, ?)',
                 {}, $id,
                 $faction->{email}, $faction->{name},
                 $action_required,
                 $leech_required,
                 $faction->{VP},
                 $faction->{rank},
                 $faction->{start_order});
    }

    $dbh->commit(); 
}

END {
    $dbh->disconnect();
}
