use strict;

package DB::Connection;
use Exporter::Easy (
    EXPORT => [ qw(get_db_connection) ],
    OK => [ qw(get_db_connection) ],
);

use DBI;

sub get_db_connection {
    DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                 { AutoCommit => 1, RaiseError => 1, pg_enable_utf8 => 1, client_encoding => 'UTF-8' });
}

1;

