#!/usr/bin/perl -w

use POSIX qw(chdir);
use CGI qw(:cgi);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

chdir dirname $0;

BEGIN { push @INC, "../../git/src"; }

use tracker;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $q = CGI->new;
my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;
my $max_row = $q->param('max-row');

my @rows = read_file("../../data/read/$id");
my $res = terra_mystica::evaluate_game { rows => \@rows, max_row => $max_row };

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

print_json $res;



