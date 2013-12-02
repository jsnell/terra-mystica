#!/usr/bin/perl -w

use strict;

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

sub add_user {
    my ($user, $email, $hashed_password) = @_;

    my $dbh = get_db_connection;

    my ($already_done) = $dbh->selectrow_array("select count(*) from email where lower(address) = lower(?) and player = ?", {}, $email, $user);

    if (!$already_done) {
        $dbh->do('begin');
        $dbh->do('insert into player (username, displayname, password) values (?, ?, ?)', {},
             $user, $user, $hashed_password);
        $dbh->do('insert into email (address, player, validated, is_primary) values (lower(?), ?, ?, true)',
                 {}, $email, $user, 1);
        $dbh->do('commit');
    }

    $dbh->disconnect();

    $already_done;
}

sub check_token {
    my ($secret, $iv) = get_secret;

    add_user decrypt_validation_token $secret, $token;
}

eval {
    my $already_done = check_token;
    if ($already_done) {
        print "<h3>Account already exists</h3>";
    } else {
        print "<h3>Account created</h3>";
    }
}; if ($@) {
    print STDERR "token: $token\n";
    print STDERR $@;
    print "<h3>Validation failed</h3>";
}
