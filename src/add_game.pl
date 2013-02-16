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

my @bon = shuffle map { "Bon$_" } 1..9;
my @score = shuffle map { "Score$_" } 1..8;

for (0..4) {
    print $writefd "delete $bon[$_]\n";
}

print $writefd "\n";
print $writefd "score ", join  ",", @score[0..5];
print $writefd "\n";

close $writefd;

system("ln -s ../$write $read");
system("git add $read $write");
system("git commit $read $write -m add");

print "http://terra.snellman.net/game/$id\n";
print "http://terra.snellman.net/edit/${id}_${hash}\n";
