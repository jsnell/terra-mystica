#!/usr/bin/perl -w

use strict;

package DB::IndexGame;
use Exporter::Easy (EXPORT => [ 'index_game' ]);

use DB::UserValidate;

use List::Util qw(max);
use POSIX qw(strftime);

sub index_game {
    my ($dbh, $id, $write_id, $game, $timestamp) = @_;

    $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime ($timestamp || time);

    my $player_count = 0;
    eval {
        $player_count = max(scalar @{$game->{order}},
                            scalar @{$game->{players}});
    };

    my ($res) = $dbh->do(
        'update game set needs_indexing=?, write_id=?, finished=?, round=?, last_update=?, player_count=?, game_options=?, base_map=?, non_standard=? where id = ?',
        {},
        0, $write_id, 1*(!!$game->{finished}), $game->{round}, $timestamp, 
        $player_count,
        [ grep { $game->{options}{$_} } keys %{$game->{options}} ],
        $game->{map_variant},
        $game->{non_standard} || 0,
        $id);

    if (!defined $game->{player_count} or
        $player_count >= $game->{player_count}) {
        set_game_roles($dbh, $id, $game);
    }
    set_game_players($dbh, $id, $game);
}

sub set_game_roles {
    my ($dbh, $id, $game) = @_;

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

        $dbh->do('insert into game_role (game, email, faction, action_required, leech_required, vp, rank, start_order, dropped) values (?, lower(?), ?, ?, ?, ?, ?, ?, ?)',
                 {}, $id,
                 $faction->{email}, $faction->{name},
                 $action_required,
                 $leech_required,
                 $faction->{VP},
                 $faction->{rank},
                 $faction->{start_order},
                 $faction->{dropped} // 0);
    }
}

my %email_cache = ();

sub set_game_players {
    my ($dbh, $id, $game) = @_;

    my @players = @{$game->{players}};

    if (!@players) {
        @players = ();
        for my $faction_name (@{$game->{order}}) {
            my $faction = $game->{factions}{$faction_name};
            push @players, {
                email => $faction->{email},
                name => $faction->{player},
                index => scalar @players,
            };
        }
    }

    for my $player (@players) {
        next if defined $player->{username};

        my $email = $player->{email};
        next if !defined $email;

        my $username_from_email;
        if (exists $email_cache{$email}) {
            $username_from_email = $email_cache{$email}
        } else {
            eval {
                $username_from_email = check_email_is_registered $dbh, $email;
            };
            $email_cache{$email} = $username_from_email;
        };
        $player->{username} = $username_from_email;
    } 

    my @no_username = grep { !defined $_->{username} } @players;
    if (!@players or @no_username) {
        return;
    }

    $dbh->do("delete from game_player where game=?",
             {},
             $id);

    for my $player (@players) {
        $dbh->do("insert into game_player (game, player, sort_key, index) values (?, ?, ?, ?)",
                 {},
                 $id, $player->{username}, $player->{name}, $player->{index});
    }
}
    
1;

