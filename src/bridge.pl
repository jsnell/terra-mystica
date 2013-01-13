#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);
use Fatal qw(chdir open);

chdir dirname $0;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

$ENV{QUERY_STRING} =~ m{game=/\w+/([a-zA-Z0-9]+)}g;
my ($id) = $1;

exec "/usr/bin/perl", "../../git/src/tracker.pl", "../../data/read/$id";



