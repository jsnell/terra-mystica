#!/usr/bin/perl -w

use strict;

use POSIX qw(chdir);
use File::Basename qw(dirname);
use CGI qw(:cgi);
use Fatal qw(chdir open);

chdir dirname $0;

my $q = CGI->new;

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;

my $new_content = $q->param('content');

open my $fh, ">", "../../data/write/$id.new";

print $fh $new_content;

print "Content-type: text/plain\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

