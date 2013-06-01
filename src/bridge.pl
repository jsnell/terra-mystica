#!/usr/bin/perl -w

use POSIX qw(chdir);
use CGI qw(:cgi);
use DBI;
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

chdir dirname $0;

use exec_timer;
use game;
use rlimit;
use tracker;

my $q = CGI->new;

if ($q->request_method eq "OPTIONS") {
    print "Access-Control-Allow-Origin: *\r\n";
    print "Access-Control-Allow-Headers: X-Prototype-Version, X-Requested-With\r\n";
    print "\r\n";
    exit 0;
}

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "Access-Control-Allow-Origin: *\r\n";
print "Access-Control-Expose-Headers: X-JSON\r\n";

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

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1, RaiseError => 1});

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

    my $res = terra_mystica::evaluate_game { rows => \@rows, max_row => $max_row };
    print_json $res;
} else {
    print "Status: 404 Not Found\r\n";
    print "\r\n";

    my $res = { error => [ "Unknown game: $id" ] };
    print_json $res;
}


