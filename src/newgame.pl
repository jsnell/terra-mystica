#!/usr/bin/perl -w

use CGI qw(:cgi);
use DBI;
use JSON;
use POSIX qw(chdir);

use create_game;
use lockfile;
use session;

my $q = CGI->new;

my $username = username_from_session_token $q->cookie('session-token') // '';
if (!$username) {
    print "Status: 303\r\n";
    print "Location: /login/#required\r\n";
    print "Cache-Control: no-cache\r\n";
    print "\r\n";
    exit;
}

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0 });

my ($email) = $dbh->selectrow_array("select address from email where player = ? limit 1", {}, $username);

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

if (-f "../../data/read/$gameid") {
    error "Game $gameid already exists";
}

chdir "../../data";
my $lockfile = lockfile::get "lock";
lockfile::lock $lockfile;

eval {
    my $write_id = create_game $gameid, $email;

    print encode_json {
        error => [],
        link => "/edit/$write_id"
    };
}; if ($@) {
    error $@;
}

lockfile::unlock $lockfile;
