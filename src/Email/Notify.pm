#!/usr/bin/perl -w

use strict;

package Email::Notify;
use Exporter::Easy (EXPORT => [ 'notify_after_move',
                                'notify_game_started',
                                'notify_new_chat' ]);

use DB::EditLink;
use Game::Constants;
use Net::SMTP;
use Util::SiteConfig;

my $domain = "https://$config{domain}";

sub notify_by_email {
    my ($game, $email, $subject, $body) = @_;

    return if !$body or !$subject or !$email;

    my $smtp = Net::SMTP->new('localhost', ( Debug => 0 ));

    $smtp->mail("www-data\@$config{email_domain}");
    if (!$smtp->to($email)) {
        print STDERR "Invalid email address $email\n";
    } else {
        $smtp->data();
        $smtp->datasend("To: $email\n");
        $smtp->datasend("From: TM Game Notification <noreply+notify-game-$game->{name}\@$config{email_domain}>\n");
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

Link: $domain$link";

    if ($faction->{recent_moves}) {
        $body .= "\n\nThe following has happened since your last full move:\n";
        for (@{$faction->{recent_moves}}) {
            $body .= "  $_\n";
        }
    } else {
        $body .= "

An action was taken by $who_moved:
$moves

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    }

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

sub notification_text_for_game_over {
    my ($game) = @_;
    my $order = join("\n",
                     map { "$_->{VP} ".pretty_faction_name($game, $_->{name}) }
                     sort { $b->{VP} <=> $a->{VP} }
                     grep { $_->{VP} } values %{$game->{factions}});

    my $subject = "Terra Mystica PBEM ($game->{name}) - game over";
    my $body = "
Game $game->{name} is over:

$order

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

sub notification_text_for_game_start {
    my ($game) = @_;

    my $i = 1;
    my $order = join("\n",
                     map { $i++.". ".($_->{display} // $_->{username}) }
                     @{$game->{players}});

    my $subject = "Terra Mystica PBEM ($game->{name}) - game started";
    my $body = "
Game $game->{name} has been started with the following players:

$order

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

sub fetch_email_settings {
    my ($dbh, $email) = @_;
    my $settings = $dbh->selectrow_hashref(
        "select email_notify_turn, email_notify_all_moves, email_notify_chat, email_notify_game_status from player where username=(select player from email where address=lower(?))",
        {},
        $email);

    $settings;
}

sub pretty_faction_name {
    my ($game, $faction) = @_;
    my $faction_pretty = $faction;
    if (exists $faction_setups{$faction}) {
        $faction_pretty = $faction_setups{$faction}{display};
    }
    my $displayname = $game->{factions}{$faction}{displayname};
    if (defined $displayname) {
        $faction_pretty .= " ($displayname)";
    }

    $faction_pretty;
}

sub notify_after_move {
    my ($dbh, $write_id, $game, $who_moved, $moves) = @_;
    my $who_moved_pretty = pretty_faction_name $game, $who_moved;

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
        next if !$game->{finished} and ($faction->{name} eq $who_moved);

        my $acting = $acting{$faction->{name}};
        my ($subject, $body) =
            ($game->{finished} ?
             notification_text_for_game_over $game :
             ($acting ?
              notification_text_for_active $dbh, $write_id, $game, $email, $faction, $who_moved_pretty, $moves :
              notification_text_for_observer $game, $who_moved_pretty, $moves));
        my $send = 0;

        if ($game->{finished}) {
            $send = $settings->{email_notify_game_status};
        } elsif (($acting and $settings->{email_notify_turn}) or
                 ($settings->{email_notify_all_moves})) {
            $send = 1;
        }

        if ($send) {
            notify_by_email $game, $email, $subject, $body;
        }
    }
}

sub notify_new_chat {
    my ($dbh, $game, $who_sent, $message) = @_;
    my $who_sent_pretty = pretty_faction_name $game, $who_sent;

    $message =~ s/^/  /gm;

    for my $faction (values %{$game->{factions}}) {
        my $email = $faction->{email};
        my $settings = fetch_email_settings $dbh, $email;
        my ($subject, $body) =
            notification_text_for_chat $game, $who_sent_pretty, $message;

        next if $who_sent eq $faction->{name};

        if ($settings->{email_notify_chat}) {
            notify_by_email $game, $email, $subject, $body;
        }
    }
}

sub notify_game_started {
    my ($dbh, $game) = @_;

    return if !$game->{options}{'email-notify'};

    for my $player (@{$game->{players}}) {
        my $email = $player->{email};
        my $settings = fetch_email_settings $dbh, $email;
        my ($subject, $body) =
            notification_text_for_game_start $game;

        next if !$settings;
        next if !$settings->{email_notify_game_status};

        notify_by_email $game, $email, $subject, $body;
    }
}

1;

