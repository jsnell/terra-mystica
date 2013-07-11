#!/usr/bin/perl -w

use CGI qw(:cgi);

use File::Slurp;

use session;

my $q = CGI->new;

ensure_csrf_cookie $q;

print "Content-type: text/html\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $path_info = $q->path_info();
my $file;

if ($path_info eq '/') {
    $file = 'index.html';
} else {
    ($file) = ($path_info =~ m{^/([a-z]+)/}g);
    $file .= ".html";
}

print read_file "../$file";

