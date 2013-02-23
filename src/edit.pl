#!/usr/bin/perl -w

use CGI qw(:cgi);
use Crypt::CBC;
use Digest::SHA1  qw(sha1_hex);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

use tracker;

chdir dirname $0;

my $q = CGI->new;

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9_]}{}g;

my $file = "../../data/write/$id";

if (!-f $file) {
    die "Can't open $file";
}

my $data = read_file($file);

my $res = terra_mystica::evaluate_game { rows => [ split /\n/, $data ] };

my $secret = read_file("../../data/secret");
my $iv = read_file("../../data/iv");

for my $faction (values %{$res->{factions}}) {
    my ($game, $game_secret) = ($id =~ /(.*?)_(.*)/g);
    $game_secret = pack "h*", $game_secret;
    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $game_secret ^ $faction->{name};
    my $key = unpack "h*", $cipher->encrypt($data);

    $faction->{edit_link} = "/faction/$game/".($faction->{name})."/$key";
}

my $out = encode_json {
    data => $data,
    hash => sha1_hex($data),
    action_required => $res->{action_required},
    factions => $res->{factions},
};

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

print $out;
