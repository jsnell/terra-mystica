#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);
use CGI qw(:cgi);
use Fatal qw(chdir open);

chdir dirname $0;

my $q = CGI->new;

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;

my $file = "../data/write/$id";

if (!-f $file) {
    die "Can't open $file";
}

local @ARGV = $file;

print "Content-type: text/plain\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

while (<>) {
    print "$_"
}
