#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi -utf8);
use Crypt::CBC;
use JSON;
use utf8 qw(decode);

use db;
use secret;
use session;

my $q = CGI->new;
my $dbh = get_db_connection;

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
    my ($username, $displayname) = $dbh->selectrow_array(
        "select username, displayname from player where username = ?",
        {},
        $username);
    $res{username} = $username;
    $res{displayname} = $displayname;

    my $rows = $dbh->selectall_arrayref(
        "select address, validated from email where player = ?",
        {},
        $username);

    for (@{$rows}) {
        $res{email}{$_->[0]}{validated} = !!$_->[1];
    }
}

sub save_user_settings {
    my $displayname = $q->param('displayname');

    if (length $displayname > 30) {
        error "Display Name too long";
    }

    $dbh->do("update player set displayname=? where username=?",
             {},
             $displayname,
             $username);
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

