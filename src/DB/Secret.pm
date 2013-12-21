#!/usr/bin/perl -w

use strict;

package DB::Secret;
use Exporter::Easy (EXPORT => [ 'get_secret' ]);

use DB::Connection;

sub get_secret {
    my $dbh = shift || get_db_connection;

    $dbh->selectrow_array("select secret, shared_iv from secret limit 1");
}

1;
