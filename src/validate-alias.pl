#!/usr/bin/perl -w

use CGI qw(:cgi);

use cryptutil;
use db;
use secret;

print "Content-type: text/html\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my @error = ();

my $q = CGI->new;
my $token = $q->param('token');

sub add_alias {
    my ($user, $email) = @_;

    my $dbh = get_db_connection;

    my ($already_done) = $dbh->selectrow_array("select count(*) from email where lower(address) = lower(?) and player = ?", {}, $email, $user);

    if (!$already_done) {
        $dbh->do('begin');
        $dbh->do('insert into email (address, player, validated, is_primary) values (lower(?), ?, ?, false)',
                 {}, $email, $user, 1);
        $dbh->do('commit');
    }

    $dbh->disconnect();
}

sub check_token {
    my ($secret, $iv) = get_secret;

    add_alias decrypt_validation_token $secret, $token;
}

eval {
    check_token;
    print "<h3>Email alias registered</h3>";
}; if ($@) {
    print STDERR "token: $token\n";
    print STDERR $@;
    print "<h3>Validation failed</h3>";
}
