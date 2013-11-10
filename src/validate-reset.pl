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

sub reset_password {
    my ($user, $email, $hashed_password) = @_;

    my $dbh = get_db_connection;

    $dbh->do('begin');

    $dbh->do('update player set password=? where username=?',
             {},
             $hashed_password,
             $user);

    $dbh->do('commit');

    $dbh->disconnect();
}

sub check_token {
    my ($secret, $iv) = get_secret;

    reset_password decrypt_validation_token $secret, $token;
}

eval {
    check_token;
    print "<h3>Password reset</h3>";
}; if ($@) {
    print STDERR "token: $token\n";
    print STDERR $@;
    print "<h3>Validation failed</h3>";
}
