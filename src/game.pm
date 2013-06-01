#!/usr/bin/perl -w

use strict;
use Digest::SHA1 qw(sha1_hex);
use Fatal qw(chdir open);

use indexgame;
use save;

sub get_game_content {
    my ($id, $write_id) = @_;
    my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                           { AutoCommit => 0, RaiseError => 1});

    my ($actual_write_id, $content) =
        $dbh->selectrow_array("select write_id, commands from game where id=?",
                              {},
                              $id);

    if (defined $write_id) {
        if ($write_id ne $actual_write_id) {
            die "Invalid write_id $write_id"
        }
    } else {
        $content =~ s{email.*}{}g;
    }

    $dbh->disconnect();

    return $content;
}

1;
