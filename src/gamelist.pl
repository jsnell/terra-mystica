#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);
use JSON;

use natural_cmp;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

chdir dirname $0;
my @ids = glob "../../data/read/*";
s{.*/}{} for @ids;

print encode_json [ map {
                      { id => $_ }   
                    } sort {
                        natural_cmp $a, $b;
                    } @ids ];


