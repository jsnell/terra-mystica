#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Crypt::CBC;
use DBI;
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

my $q = CGI->new;
my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1, RaiseError => 1});

chdir dirname "$0";
chdir "../../data/write";

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9_]}{}g;

my $faction_name = $q->param('preview-faction');
my $faction_key = $q->param('faction-key');
my $set_note = $q->param('set-note');

sub verify_key {
    my $secret = read_file("../secret");
    my $iv = read_file("../iv");

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);
    my $write_id = "${id}_$game_secret";
    die "Invalid faction key\n" if
        $write_id =~ /[^a-zA-z0-9_]/ or !(-f $write_id);
}

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my %res = (
    error => "",
);

eval {
    verify_key;
    if (defined $set_note) {
        $res{note} = $set_note;

        $dbh->do('begin');
        my $res = $dbh->do(
            "delete from game_note where faction = ? and game = ?",
            {},
            $faction_name,
            $id);
        $res = $dbh->do(
            "insert into game_note (faction, game, note) values (?, ?, ?)",
            {},
            $faction_name,
            $id,
            $set_note);
        $dbh->commit();
    } else {
        my $rows = $dbh->selectall_arrayref(
            "select note from game_note where faction = ? and game = ?",
            {},
            $faction_name,
            $id);
        $res{note} = $rows->[0][0];
    }
}; if ($@) {
    $res{error} = "$@";
}

my $out = encode_json \%res;
print $out;

