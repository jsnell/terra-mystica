#!/usr/bin/perl -w

use CGI qw(:cgi);
use Digest::SHA1  qw(sha1_hex);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

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

my $out = encode_json {
    data => $data,
    hash => sha1_hex($data),
};

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

print $out;
