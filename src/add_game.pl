#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);
use Fatal qw(open);
use File::Basename;

BEGIN { push @INC, dirname $0 }

use create_game;

if (!-d "read/") {
    die "Should be run in data/\n"
}

if (!-w ".git/index") {
    die "Running without sufficient privileges\n"
}

my $id = shift;
my $admin = shift;

die "Usage: $0 id [admin]\n" if !$id or $id =~ /[^A-Za-z0-9]/;

my ($write_id) = create_game $id, $admin;

print "http://terra.snellman.net/game/$id\n";
print "http://terra.snellman.net/edit/$write_id\n";
