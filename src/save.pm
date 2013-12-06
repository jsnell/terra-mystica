#!/usr/bin/perl -w

use strict;

use File::Temp qw(tempfile);

use game;
use indexgame;
use tracker;
use user_validate;

sub save {
    my ($dbh, $id, $new_content, $game, $timestamp) = @_;

    my ($read_id) = $id =~ /(.*?)_/g;
    index_game $dbh, $read_id, $id, $game, $timestamp;

    $dbh->do("update game set commands=? where id=?", {},
             $new_content, $read_id);
}

sub verify_email_notification_settings {
    my ($dbh, $game) = @_;

    return if !$game->{options}{'email-notify'};

    for my $faction (values %{$game->{factions}}) {
        if (!$faction->{email}) {
            die "When option email-notify is on, all players must have an email address defined ('$faction->{player}' does not)\n"
        }

        my ($email_valid) =
            $dbh->selectrow_array("select count(*) from email where address=lower(?) and validated=true",
                                  {},
                                  $faction->{email});

        if (!$email_valid) {
            die "When option email-notify is on, all players must be registered ('$faction->{player}' is not)\n"
        }                              
    }
}

sub verify_and_save {
    my ($dbh, $read_id, $write_id, $new_content, $game, $timestamp) = @_;

    for my $faction (values %{$game->{factions}}) {
        if (defined $faction->{email} and !defined $faction->{username}) {
            $faction->{username} = check_email_is_registered $dbh, $faction->{email};
        } elsif (defined $faction->{username}) {
            ($faction->{username},
             $faction->{email}) =
                 check_username_is_registered $dbh, $faction->{username};
        }
    }

    for my $player (@{$game->{players}}) {
        if (defined $player->{email} and !defined $player->{username}) {
            $player->{username} = check_email_is_registered $dbh, $player->{email};
        } elsif (defined $player->{username}) {
            ($player->{username}, $player->{email}) =
                check_username_is_registered $dbh, $player->{username};
        }
    }

    verify_email_notification_settings $dbh, $game;

    save $dbh, $write_id, $new_content, $game, $timestamp;
}

sub evaluate_and_save {
    my ($dbh, $read_id, $write_id, $new_content) = @_;

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, $new_content ],
        players => get_game_players($dbh, $read_id),
        delete_email => 0
    };

    if (!@{$res->{error}}) {
        eval {
            my ($timestamp) =
                $dbh->selectrow_array("select extract(epoch from last_update) from game where id=?",
                                      {},
                                      $read_id);
            if (!defined $timestamp) {
                $timestamp = time;
            }
            verify_and_save $dbh, $read_id, $write_id, $new_content, $res, $timestamp;
        }; if ($@) {
            print STDERR "error: $@\n";
            $res->{error} = [ $@ ]
        }
    };

    $res;
};


1;
