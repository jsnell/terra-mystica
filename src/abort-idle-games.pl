#!/usr/bin/perl -w

use strict;

use File::Basename;

BEGIN { push @INC, dirname $0 }

use DB::Connection;

my $dbh = get_db_connection;

$dbh->do("begin");
my $count = $dbh->do("update game set aborted=true, finished=true where last_update < now() - interval '2 weeks' and not finished",
                     {},
                     ());
if ($count > 0) {
    print STDERR "Aborting $count games\n";
}
$dbh->do("commit");
