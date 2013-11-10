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

    $dbh->do('begin');
    $dbh->do('insert into player (username, displayname, password) values (?, ?, ?)', {},
             $user, $user, $hashed_password);
    $dbh->do('insert into email (address, player, validated) values (lower(?), ?, ?)',
             {}, $email, $user, 1);
    $dbh->do('commit');

    $dbh->disconnect();
}

sub check_token {
    my ($secret, $iv) = get_secret;

    add_user decrypt_validation_token $secret, $token;
}

eval {
    check_token;
    print "<h3>Account created</h3>";
}; if ($@) {
    print STDERR "token: $token\n";
    print STDERR $@;
    print "<h3>Validation failed</h3>";
}
