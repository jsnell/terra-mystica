#!/usr/bin/perl -w

use CGI qw(:cgi);
use Digest::SHA1 qw(sha1_hex);
use JSON;

use db;
use editlink;
use game;
use session;
use tracker;

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $q = CGI->new;

my $write_id = $q->param('game');
$write_id =~ s{.*/}{};
$write_id =~ s{[^A-Za-z0-9_]}{}g;

my $dbh = get_db_connection;

my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

if (!defined $username) {
    my $out = encode_json {
        error => ["Not logged in"],
        location => "/login/",
    };

    print $out;
} else {
    my ($read_id) = $write_id =~ /(.*?)_/g;
    my $data = get_game_content $dbh, $read_id, $write_id;

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, $data ],
        players => get_game_players($dbh, $read_id),
    };

    # Development hack
    if ($username eq 'jsnell') {
        for my $faction (values %{$res->{factions}}) {
            $faction->{edit_link} = edit_link_for_faction $dbh, $write_id, $faction->{name};
        }
    }

    my $out = encode_json {
        data => $data,
        error => [],
        hash => sha1_hex($data),
        action_required => $res->{action_required},
        factions => $res->{factions},
    };

    print $out;
}
    
