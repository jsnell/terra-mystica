#!/usr/bin/perl -w

use CGI qw(:cgi);
use JSON;

use db;
use create_game;
use game;
use session;

my $q = CGI->new;

my $dbh = get_db_connection;

print "Content-Type: text/json\r\n";
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
        error => "Login required",
        link => "/login/#required",
    };
    exit;
}

my $gameid = $q->param('gameid');
if (!$gameid) {
    error "No game name";
}

if ($gameid =~ /([^A-Za-z0-9])/) {
    error "Invalid character in game id '$1'";
}

begin_game_transaction $dbh, $gameid;

if (game_exists $dbh, $gameid) {
    error "Game $gameid already exists";
}

my ($email) = $dbh->selectrow_array("select address from email where player = ? limit 1", {}, $username);

eval {
    my $write_id = create_game $dbh, $gameid, $email;

    print encode_json {
        error => [],
        link => "/edit/$write_id"
    };
}; if ($@) {
    error $@;
}

finish_game_transaction $dbh;
