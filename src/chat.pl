#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi -utf8);
use Crypt::CBC;
use JSON;

use db;
use notify;
use secret;

my $q = CGI->new;
my $dbh = get_db_connection;

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9_]}{}g;

my $faction_name = $q->param('faction');
my $faction_key = $q->param('faction-key');
my $add_message = $q->param('add-message');

sub verify_key {
    my ($secret, $iv) = get_secret $dbh;

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);

    my $write_id = "${id}_$game_secret";
    my $valid = $dbh->selectrow_array("select count(*) from game where write_id=?", {}, $write_id);

    die "Invalid faction key\n" if !$valid;
}

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my %res = (
    error => "",
);

eval {
    verify_key;
    if (defined $add_message) {
        $dbh->do('begin');
        $dbh->do(
            "insert into chat_message (faction, game, message) values (?, ?, ?)",
            {},
            $faction_name,
            $id,
            $add_message);
        $dbh->do('commit');

        my $factions = $dbh->selectall_arrayref(
            "select faction as name, email from game_role where game = ? and faction != 'admin' and email is not null",
            { Slice => {} },
            $id);

        notify_new_chat $dbh, {
            name => $id,
            factions => { map { ($_->{name}, $_) } @{$factions} }
        }, $faction_name, $add_message;
    }

    my $rows = $dbh->selectall_arrayref(
        "select faction, message, extract(epoch from now() - posted_at) as message_age from chat_message where game = ? order by posted_at asc",
        { Slice => {} },
        $id);
    $res{messages} = $rows;
}; if ($@) {
    $res{error} = "$@";
}

my $out = encode_json \%res;
print $out;

