#!/usr/bin/perl -w

use CGI qw(:cgi);
use DBI;
use JSON;
use POSIX qw(chdir);

use create_game;
use game;
use session;

my $q = CGI->new;

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1 });

my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

if (!$username) {
    print "Status: 303\r\n";
    print "Location: /login/#required\r\n";
    print "Cache-Control: no-cache\r\n";
    print "\r\n";
    exit;
}

my $gameid = $q->param('gameid');
if (!$gameid) {
    print "Location: /newgame/\r\n";
    print "Cache-Control: no-cache\r\n";
    print "\r\n";
    exit;
}

print "Content-Type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

sub error {
    print encode_json {
        error => \@_,
    };
    exit;
};

if ($gameid =~ /([^A-Za-z0-9])/) {
    error "Invalid character in game id '$1'";
}

begin_game_transaction $dbh, $gameid;

if (game_exists $dbh, $gameid) {
    error "Game $gameid already exists";
}

my ($email) = $dbh->selectrow_array("select address from email where player = ? limit 1", {}, $username);

chdir "../../data";

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
