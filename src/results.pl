#!/usr/bin/perl -w

use strict;

use exec_timer;

use CGI qw(:cgi);
use JSON;

use rlimit;
use results;
use secret;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $secret = get_secret;

my %res = get_finished_game_results $secret;

print encode_json \%res;
