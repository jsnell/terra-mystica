#!/usr/bin/perl -w

use strict;

use editlink;
use Net::SMTP;

sub notify_by_email {
    my ($email, $subject, $body) = @_;

    return if !$body or !$subject or !$email;

    my $smtp = Net::SMTP->new('localhost', ( Debug => 0 ));

    $smtp->mail("www-data\@terra.snellman.net");
    if (!$smtp->to($email)) {
        print STDERR "Invalid email address $email\n";
    } else {
        $smtp->data();
        $smtp->datasend("To: $email\n");
        $smtp->datasend("From: noreply+notify\@terra.snellman.net\n");
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

    my $domain = "http://terra.snellman.net";
    my $link = edit_link_for_faction $dbh, $write_id, $faction->{name};
    my $body = "
It's your turn to move in Terra Mystica game $game->{name}.

Link: $domain$link

An action was taken by $who_moved:
$moves
";

    ($subject, $body);
}

sub notification_text_for_observer {
    my ($game, $who_moved, $moves) = @_;

    my $subject = "Terra Mystica PBEM ($game->{name})";
    my $body = "
An action was taken in game $game->{name} by $who_moved:

$moves
";
    ($subject, $body);
}

sub notify_after_move {
    my ($dbh, $write_id, $game, $who_moved, $moves) = @_;
    my %acting = ();

    return if !$game->{options}{'email-notify'};

    for (@{$game->{action_required}}) {
        $acting{$_->{faction}} = 1;
    }

    $moves =~ s/^$who_moved:/  /gm;

    for my $faction (values %{$game->{factions}}) {
        my $email = $faction->{email};
        my $acting = $acting{$faction->{name}};
        my ($subject, $body) =
            ($acting ?
             notification_text_for_active $dbh, $write_id, $game, $email, $faction, $who_moved, $moves :
             notification_text_for_observer $game, $who_moved, $moves);

        if ($acting) {
            notify_by_email $email, $subject, $body;
        }
    }
}

1;

