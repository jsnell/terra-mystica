#!/usr/bin/perl -w

use strict;

use editlink;
use Net::SMTP;

my $domain = "http://terra.snellman.net";

sub notify_by_email {
    my ($game, $email, $subject, $body) = @_;

    return if !$body or !$subject or !$email;

    my $smtp = Net::SMTP->new('localhost', ( Debug => 0 ));

    $smtp->mail("www-data\@terra.snellman.net");
    if (!$smtp->to($email)) {
        print STDERR "Invalid email address $email\n";
    } else {
        $smtp->data();
        $smtp->datasend("To: $email\n");
        $smtp->datasend("From: TM Game Notification <noreply+notify-game-$game->{name}\@terra.snellman.net>\n");
        $smtp->datasend("Subject: $subject\n");
        $smtp->datasend("\n");
        $smtp->datasend("$body\n");
        $smtp->dataend();
    }

    $smtp->quit;
}

sub notification_text_for_active {
    my ($dbh, $write_id, $game, $email, $faction, $who_moved, $moves) = @_;

    my $subject = "Terra Mystica PBEM ($game->{name}) - your move";

    my $link = edit_link_for_faction $dbh, $write_id, $faction->{name};
    my $body = "
It's your turn to move in Terra Mystica game $game->{name}.

Link: $domain$link

An action was taken by $who_moved:
$moves

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";

    ($subject, $body);
}

sub notification_text_for_observer {
    my ($game, $who_moved, $moves) = @_;

    my $subject = "Terra Mystica PBEM ($game->{name})";
    my $body = "
An action was taken in game $game->{name} by $who_moved:

$moves

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

sub notification_text_for_chat {
    my ($game, $who_moved, $moves) = @_;

    my $subject = "Terra Mystica PBEM ($game->{name})";
    my $body = "
A chat message was sent in $game->{name} by $who_moved:

$moves

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

sub fetch_email_settings {
    my ($dbh, $email) = @_;
    my $settings = $dbh->selectrow_hashref(
        "select email_notify_turn, email_notify_all_moves, email_notify_chat from player where username=(select player from email where address=?)",
        {},
        $email);

    $settings;
}

sub notify_after_move {
    my ($dbh, $write_id, $game, $who_moved, $moves) = @_;
    my %acting = ();

    return if !$game->{options}{'email-notify'};

    for (@{$game->{action_required}}) {
        $acting{$_->{faction} // $_->{player_index}} = 1;
    }

    $moves =~ s/^$who_moved:/  /gm;

    # TODO: should send a message when game is over

    for my $faction (values %{$game->{factions}}) {
        my $email = $faction->{email};
        my $settings = fetch_email_settings $dbh, $email;

        # Shouldn't happen, but ensure that we never send email to an
        # unregistered address.
        next if !$settings;
        # Don't send notifications for your own moves.
        next if $faction->{name} eq $who_moved;

        my $acting = $acting{$faction->{name}};
        my ($subject, $body) =
            ($acting ?
             notification_text_for_active $dbh, $write_id, $game, $email, $faction, $who_moved, $moves :
             notification_text_for_observer $game, $who_moved, $moves);

        if ($acting and $settings->{email_notify_turn} or
            $settings->{email_notify_all_moves}) {
            notify_by_email $game, $email, $subject, $body;
        }
    }
}

sub notify_new_chat {
    my ($dbh, $game, $who_sent, $message) = @_;

    $message =~ s/^/  /gm;

    for my $faction (values %{$game->{factions}}) {
        my $email = $faction->{email};
        my $settings = fetch_email_settings $dbh, $email;
        my ($subject, $body) =
            notification_text_for_chat $game, $who_sent, $message;

        next if $who_sent eq $faction->{name};

        if ($settings->{email_notify_chat}) {
            notify_by_email $game, $email, $subject, $body;
        }
    }
}

1;

