#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);

chdir dirname $0;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $id = $ENV{QUERY_STRING};
$id =~ s/[^0-9]//g;

exec "/usr/bin/perl", "../../git/src/tracker.pl", "../../git/test/testgame$id.txt";



