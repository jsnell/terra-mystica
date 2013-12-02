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
use user_validate;
use tracker;

my $q = CGI->new;

my $write_id = $q->param('game');
$write_id =~ s{.*/}{};
$write_id =~ s{[^A-Za-z0-9_]}{}g;
my ($read_id) = $write_id =~ /(.*?)_/g;

my $orig_hash = $q->param('orig-hash');
my $new_content = $q->param('content');

my $dbh = get_db_connection;

begin_game_transaction $dbh, $read_id;

my $orig_content = get_game_content $dbh, $read_id, $write_id;

my $res = {};

if (sha1_hex($orig_content) ne $orig_hash) {
    print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
    $res->{error} = [
        "Someone else made changes to the game. Please reload\n"
    ];
} else {
    $res = evaluate_and_save $dbh, $read_id, $write_id, $new_content;
}

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
