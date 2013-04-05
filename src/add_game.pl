#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);
use List::Util qw(shuffle);
use Fatal qw(open);

if (!-d "read/") {
    die "Should be run in data/\n"
}

if (!-w ".git/index") {
    die "Running without sufficient privileges\n"
}

my $id = shift;

die "Usage: $0 id\n" if !$id or $id =~ /[^A-Za-z0-9]/;

my $hash = sha1_hex($id . rand(2**32) . time);
my $write = "write/${id}_$hash";
my $read = "read/$id";

if (-f $read) {
    die "Game $id already exists\n";
}

open my $writefd, ">", "$write";

print $writefd "# Game $id\n\n";

print $writefd "# List players (in any order)\n";
print $writefd "# Player ... email ...\n";
print $writefd "# Player ... email ...\n";

print $writefd "\n# Randomize setup\n";
print $writefd "randomize v1 seed $id\n";

close $writefd;

system("ln -s ../$write $read");
system("git add $read $write");
system("git commit $read $write -m add");

print "http://terra.snellman.net/game/$id\n";
print "http://terra.snellman.net/edit/${id}_${hash}\n";
