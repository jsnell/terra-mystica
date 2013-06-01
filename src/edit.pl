#!/usr/bin/perl -w

use CGI qw(:cgi);
use DBI;
use Digest::SHA1 qw(sha1_hex);
use JSON;

use editlink;
use game;
use tracker;

my $q = CGI->new;

my $write_id = $q->param('game');
$write_id =~ s{.*/}{};
$write_id =~ s{[^A-Za-z0-9_]}{}g;

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1, RaiseError => 1});

my ($read_id) = $write_id =~ /(.*?)_/g;
my $data = get_game_content $dbh, $read_id, $write_id;

my $res = terra_mystica::evaluate_game { rows => [ split /\n/, $data ] };

for my $faction (values %{$res->{factions}}) {
    $faction->{edit_link} = edit_link_for_faction $dbh, $write_id, $faction->{name};
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
