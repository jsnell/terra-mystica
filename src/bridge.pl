#!/usr/bin/perl -w

use POSIX qw(chdir);
use CGI qw(:cgi);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

chdir dirname $0;

use tracker;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";

my $q = CGI->new;
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

if (-f "../../data/read/$id") {
    print "\r\n";
    my @rows = read_file("../../data/read/$id");
    push @rows, (map { "$preview_faction: $_" } split /\n/, $preview);

    my $res = terra_mystica::evaluate_game { rows => \@rows, max_row => $max_row };
    print_json $res;
} else {
    print "Status: 404 Not Found\r\n";
    print "\r\n";

    my $res = { error => [ "Unknown game: $id" ] };
    print_json $res;
}


