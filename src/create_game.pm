#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);
use Fatal qw(open);

use indexgame;

sub create_game {
    my ($id, $admin) = @_;

    die "Invalid game id $id\n" if !$id or $id =~ /[^A-Za-z0-9]/;

    my $hash = sha1_hex($id . rand(2**32) . time);
    my $write = "write/${id}_$hash";
    my $read = "read/$id";

    if (-f $read) {
        die "Game $id already exists\n";
    }

    open my $writefd, ">", "$write";

    print $writefd "# Game $id\n\n";

    if ($admin) {
        print $writefd "admin email $admin\n\n"
    }

    print $writefd "# List players (in any order) with 'player' command\n";

    print $writefd "\n# Randomize setup\n";
    print $writefd "randomize v1 seed $id\n";

    close $writefd;

    system("ln -s ../$write $read");
    system("git add $read $write > /dev/null");
    system("HOME=. git commit $read $write -m add > /dev/null");

    my $write_id = "${id}_${hash}";

    if ($admin) {
        index_game $id, $write_id, { admin => $admin };
    }

    return $write_id;
}

1;
