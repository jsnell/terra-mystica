#!/usr/bin/perl -w

use strict;

use exec_timer;

use CGI qw(:cgi);
use DBI;
use Digest::SHA1 qw(sha1_hex);
use JSON;
use File::Slurp qw(read_file);

use rlimit;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0, RaiseError => 1});
my $q = CGI->new;

my %res = ( error => '', results => [] );

my $rows = $dbh->selectall_arrayref(
    "select game, faction, vp, rank, start_order, email.player, email from game_role left join game on game=game.id left join email on email=email.address where faction != 'admin' and game.finished",
    {});

if (!$rows) {
    $res{error} = "db error";
} else {
    my $secret = read_file("../../data/secret");

    for (@{$rows}) {
        push @{$res{results}}, {
            game => $_->[0],
            faction => $_->[1],
            vp => $_->[2],
            rank => $_->[3],
            start_order => $_->[4],
            username => $_->[5],
            id_hash => ($_->[6] ? sha1_hex($_->[6] . $secret) : undef),
        }
    }
}

print encode_json \%res;

$dbh->disconnect();
