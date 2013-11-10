#!/usr/bin/perl -w

use CGI qw(:cgi);
use JSON;
use Net::SMTP;

use cryptutil;
use db;
use secret;
use session;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $dbh = get_db_connection;

my @error = ();

my $q = CGI->new;
my $email = $q->param('email');
my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

if (!@error) {
    my ($email_in_use) = $dbh->selectrow_array("select count(*) from email where lower(address) = lower(?)", {}, $email);

    if ($email_in_use) {
        push @error, "The email address is already registered";
    }
}

if (!@error) {
    my $secret = get_secret $dbh;

    my $token = encrypt_validation_token $secret, ($username, $email);
    $url = sprintf "http://terra.snellman.net/validate-alias/%s", $token;

    my $smtp = Net::SMTP->new('localhost', ( Debug => 0 ));

    $smtp->mail("www-data\@terra.snellman.net");
    if (!$smtp->to($email)) {
        push @error, "Invalid email address";
    } else {
        $smtp->data();
        $smtp->datasend("To: $email\n");
        $smtp->datasend("From: noreply+alias\@terra.snellman.net\n");
        $smtp->datasend("Subject: Email alias validation for Terra Mystica\n");
        $smtp->datasend("\n");
        $smtp->datasend("To validate this email as an alias, use the following link:\n");
        $smtp->datasend("  $url\n");
        $smtp->dataend();
    }

    $smtp->quit;
}

print encode_json {
    error => \@error,
};
