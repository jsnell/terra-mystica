#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);
use CGI qw(:cgi);
use Fatal qw(chdir open);

chdir dirname $0;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $q = CGI->new;
my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;

exec "/usr/bin/perl", "../src/tracker.pl", "../data/read/$id";



