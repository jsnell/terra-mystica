#!/usr/bin/perl -w

use CGI qw(:cgi);
use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);
use DBI;
use File::Basename qw(dirname);

use session;

my $q = CGI->new;
my $username = $q->param('username');
my $password = $q->param('password');

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0 });

my ($stored_password) = $dbh->selectrow_array("select password from player where username = ?", {}, $username);

if ($stored_password and
    $stored_password eq bcrypt($password, $stored_password)) {
    my $token = session_token $username, sprintf "%08x", rand 2**32;
    print "Status: 303\r\n";
    print "Set-Cookie: token=$token; Path=/; HttpOnly\r\n";
    print "Cache-Control: no-cache\r\n";
    print "Location: /\r\n";
    print "\r\n";
} else {
    print "Status: 303\r\n";
    print "Set-Cookie: token=; Path=/; HttpOnly\r\n";
    print "Location: /login.html#failed\r\n";
    print "Cache-Control: no-cache\r\n";
    print "\r\n";
}
