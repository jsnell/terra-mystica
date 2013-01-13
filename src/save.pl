#!/usr/bin/perl -w

use strict;

use JSON;
use POSIX qw(chdir);
use File::Basename qw(dirname);
use File::Temp qw(tempfile);
use CGI qw(:cgi);
use Fatal qw(chdir open);
use tracker;

chdir dirname $0;

my $q = CGI->new;

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;

my $new_content = $q->param('content');

my $dir = "../data/write/";

sub save {
    my ($fh, $filename) = tempfile("tmpfileXXXXXXX",
                                   DIR=>$dir);
    print $fh $new_content;
    close $fh;
    rename "$dir/$id", "$dir/$id.bak";
    rename $filename, "$dir/$id";
}

my $res = terra_mystica::evaluate_game split /\n/, $new_content;

if (!@{$res->{error}}) {
    save;
};

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $out = encode_json { error => $res->{error} };
print $out;
