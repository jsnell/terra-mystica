#!/usr/bin/perl -w

use CGI qw(:cgi);
use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);

use db;
use rlimit;
use session;

my $q = CGI->new;
my $form_username = $q->param('username');
my $password = $q->param('password');

my $dbh = get_db_connection;

print STDERR "login: $form_username\n";

my ($stored_password, $username) = $dbh->selectrow_array("select password, username from player where lower(username) = lower(?)", {}, $form_username);

my $match = 0;

if (!$stored_password) {
    print STDERR "login: invalid username\n";    
} elsif ($stored_password ne bcrypt($password, $stored_password)) {
    print STDERR "login: invalid password\n";
} else {
    print STDERR "login: ok\n";
    $match = 1;
}

if ($match) {
    my $token = session_token $dbh, $username, sprintf "%08x", rand 2**32;
    my $y = 86400*365;
    print "Status: 303\r\n";
    print "Set-Cookie: session-username=$username; Path=/; Max-Age=$y\r\n";
    print "Set-Cookie: session-token=$token; Path=/; HttpOnly; Max-Age=$y\r\n";
    print "Cache-Control: no-cache\r\n";
    print "Location: /\r\n";
    print "\r\n";
} else {
    print "Status: 303\r\n";
    print "Set-Cookie: session-username=; Path=/;\r\n";
    print "Set-Cookie: session-token=; Path=/; HttpOnly\r\n";
    print "Location: /login/#failed\r\n";
    print "Cache-Control: no-cache\r\n";
    print "\r\n";
}
