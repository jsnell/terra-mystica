#!/usr/bin/perl -w

use CGI qw(:cgi);
use JSON;

use strict;

use db;
use exec_timer;
use game;
use rlimit;
use session;
use tracker;

my $q = CGI->new;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;
my $max_row = $q->param('max-row');
my $preview = $q->param('preview');
my $preview_faction = $q->param('preview-faction');

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

my $dbh = get_db_connection;
my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

if (game_exists $dbh, $id) {
    print "\r\n";
    my @rows = get_game_commands($dbh, $id);

    if (defined $preview) {
        if ($preview_faction =~ /^player/) {
            if ($preview =~ /(setup \w+)/i) {
                push @rows, "$1\n"; 
            }
        } else {
            push @rows, (map { "$preview_faction: $_" } split /\n/, $preview);
        }
    }

    my $res = terra_mystica::evaluate_game {
        rows => \@rows,
        faction_info => get_game_factions($dbh, $id),
        players => get_game_players($dbh, $id),
        max_row => $max_row
    };
    eval {
        ($res->{chat_message_count},
         $res->{chat_unread_message_count}) = get_chat_count($dbh, $id, $username);
    };

    print_json $res;
} else {
    print "Status: 404 Not Found\r\n";
    print "\r\n";

    my $res = { error => [ "Unknown game: $id" ] };
    print_json $res;
}


