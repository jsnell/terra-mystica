use DBI;

sub get_db_connection {
    DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                 { AutoCommit => 1, RaiseError => 1, pg_enable_utf8 => 1 });
}

1;

