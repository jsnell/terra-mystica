#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Digest::SHA1  qw(sha1_hex);
use JSON;

use db;
use exec_timer;
use game;
use rlimit;
use save;
use tracker;

my $q = CGI->new;

my $write_id = $q->param('game');
$write_id =~ s{.*/}{};
$write_id =~ s{[^A-Za-z0-9_]}{}g;
my ($read_id) = $write_id =~ /(.*?)_/g;

my $orig_hash = $q->param('orig-hash');
my $new_content = $q->param('content');

my $dbh = get_db_connection;

sub verify_email_notification_settings {
    my ($dbh, $game) = @_;

    return if !$game->{options}{'email-notify'};

    for my $faction (values %{$game->{factions}}) {
        if (!$faction->{email}) {
            die "When option email-notify is on, all players must have an email address defined ('$faction->{player}' does not)\n"
        }

        my ($email_valid) =
            $dbh->selectrow_array("select count(*) from email where address=? and validated=true",
                                  {},
                                  $faction->{email});

        if (!$email_valid) {
            die "When option email-notify is on, all players must be registered ('$faction->{player}' is not)\n"
        }                              
    }
}

sub verify_and_save {
    my ($game, $timestamp) = @_;

    my $orig_content = get_game_content $dbh, $read_id, $write_id;

    if (sha1_hex($orig_content) ne $orig_hash) {
        print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
        die "Someone else made changes to the game. Please reload\n";
    }

    verify_email_notification_settings $dbh, $game;

    save $dbh, $write_id, $new_content, $game, $timestamp;
}

begin_game_transaction $dbh, $read_id;

my $res = terra_mystica::evaluate_game {
    rows => [ split /\n/, $new_content ],
    delete_email => 0
};

if (!@{$res->{error}}) {
    eval {
        my ($timestamp) =
            $dbh->selectrow_array("select extract(epoch from last_update) from game where id=?",
                                  {},
                                  $read_id);
        verify_and_save $res, $timestamp;
    }; if ($@) {
        print STDERR "error: $@\n";
        $res->{error} = [ $@ ]
    }
};

finish_game_transaction $dbh;

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $out = encode_json {
    error => $res->{error},
    hash => sha1_hex($new_content),
    action_required => $res->{action_required},
    factions => $res->{factions},
};
print $out;
