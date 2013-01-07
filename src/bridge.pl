#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);

chdir dirname $0;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache:\r\n";
print "\r\n";

exec "perl", "../src/tracker.pl", "../test/testgame2.txt";



