#!/usr/bin/perl -w

use strict;

use DBI;

sub get_secret {
    my $dbh = shift || DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                                    { AutoCommit => 1, RaiseError => 1});

    $dbh->selectrow_array("select secret, shared_iv from secret limit 1");
}

1;
