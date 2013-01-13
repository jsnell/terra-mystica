#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);
use CGI qw(:cgi);
use Fatal qw(chdir open);

chdir dirname $0;

my $q = CGI->new;

print "Content-type: text/plain\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;

local @ARGV = "../../data/write/$id";

while (<>) {
    print "$_"
}
