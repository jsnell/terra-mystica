#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);
use Fatal qw(chdir open);

use indexgame;
use save;

sub create_game {
    my ($dbh, $id, $admin) = @_;

    die "Invalid game id $id\n" if !$id or $id =~ /[^A-Za-z0-9]/;

    my $hash = sha1_hex($id . rand(2**32) . time);
    my $write = "write/${id}_$hash";
    my $read = "read/$id";

    if (-f $read) {
        die "Game $id already exists\n";
    }

    open my $writefd, ">", "$write";
    close $writefd;
    system("ln -s ../$write $read");
    system("git add $read $write > /dev/null");
    system("HOME=. git commit $read $write -m add > /dev/null");

    my $opt_admin = "";
    if ($admin) {
        $opt_admin = "admin email $admin\n\n";
    }

    my $content = <<EOF;
# Game $id

$opt_admin
# List players (in any order) with 'player' command

# Randomize setup
randomize v1 seed $id
EOF
 
    my $write_id = "${id}_${hash}";
    my $game = $admin ? { admin => $admin } : {};

    chdir "write";
    save $dbh, $write_id, $content, $game;

    return $write_id;
}

1;
