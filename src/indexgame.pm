#!/usr/bin/perl -w

use strict;

use POSIX qw(strftime);

sub index_game {
    my ($dbh, $id, $write_id, $game, $timestamp) = @_;

    $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime ($timestamp || time);

    my $player_count = 0;
    eval {
        $player_count = scalar @{$game->{order}} || scalar @{$game->{players}};
    };

    my ($res) = $dbh->do(
        'update game set needs_indexing=?, write_id=?, finished=?, round=?, last_update=?, player_count=?, wanted_player_count=? where id = ?',
        {},
        0, $write_id, 1*(!!$game->{finished}), $game->{round}, $timestamp, 
        $player_count,
        $game->{player_count},
        $id);

    $dbh->do("delete from game_role where game=? and faction != 'admin'",
             {},
             $id);

    my $pi = 0;
    my @player_roles = map {
        { name => "player".++$pi,
          email => $_->{email} }
    } @{$game->{players}};
    shift @player_roles for 1..(values %{$game->{factions}});

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
            $prev = $_;
        }
    }

    {
        my $pos = 0;
        for (@{$game->{order}}) {
            $game->{factions}{$_}{start_order} = ++$pos;
        }
    }

    for my $faction (values %{$game->{factions}},
                     @player_roles) {
        my $action_required = 0;
        my $leech_required = 0;

        for my $action (@{$game->{action_required}}) {
            my $acting = '';
            if (defined $action->{player_index}) {
                $acting = $action->{player_index};
            } elsif (defined $action->{faction}) {
                $acting = $action->{faction};
            } else {
                next;
            }

            next if $faction->{name} ne $acting;

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
}

1;

