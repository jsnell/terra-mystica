#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi -utf8);
use JSON;
use utf8 qw(decode);

use db;
use secret;
use session;

my $q = CGI->new;
my $dbh = get_db_connection;

verify_csrf_cookie_or_die $q;

print "Content-type: application/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

sub error {
    print encode_json {
        error => [ @_ ],
    };
    exit;
};

if (!$username) {
    print encode_json {
        error => ["Login required"],
        link => "/login/#required",
    };
    exit;
}

my %res = (
    error => []
);

sub fetch_user_settings {
    my $player = $dbh->selectrow_hashref(
        "select username, displayname, email_notify_turn, email_notify_all_moves, email_notify_chat from player where username = ?",
        {},
        $username);
    $res{$_} = $player->{$_} for keys %{$player};

    my $rows = $dbh->selectall_arrayref(
        "select address, validated, is_primary from email where player = ?",
        {},
        $username);

    for (@{$rows}) {
        $res{email}{$_->[0]}{validated} = !!$_->[1];
        $res{email}{$_->[0]}{is_primary} = !!$_->[2];
    }
}

sub save_user_settings {
    my $displayname = $q->param('displayname');
    my $primary_email = $q->param('primary_email');

    if (length $displayname > 30) {
        error "Display Name too long";
    }

    $dbh->do("begin");

    $dbh->do("update player set displayname=?, email_notify_turn=?, email_notify_all_moves=?, email_notify_chat=? where username=?",
             {},
             $displayname,
             $q->param('email_notify_turn'),
             $q->param('email_notify_all_moves'),
             $q->param('email_notify_chat'),
             $username);

    if ($primary_email) {
        $dbh->do("update email set is_primary=false where player=?",
                 {},
                 $username);
        $dbh->do("update email set is_primary=true where player=? and address=lower(?)",
                 {},
                 $username,
                 $primary_email);
    }

    $dbh->do("commit");
}

eval {
    if ($q->param('save')) {
        save_user_settings;
    }

    fetch_user_settings;
}; if ($@) {
    $res{error} = [ $@ ];
}

my $out = encode_json \%res;
print $out;

