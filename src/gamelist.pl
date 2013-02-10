#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);
use JSON;

chdir dirname $0;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my @ids = glob "../../data/read/*";
s{.*/}{} for @ids;

print encode_json [ map {
                      { id => $_ }   
                    } @ids ];


