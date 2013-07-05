#!/usr/bin/perl -w

use strict;

use db;

sub get_secret {
    my $dbh = shift || get_db_connection;

    $dbh->selectrow_array("select secret, shared_iv from secret limit 1");
}

1;
