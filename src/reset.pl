#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);
use JSON;
use Net::SMTP;

use cryptutil;
use db;
use secret;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my @error = ();

my $q = CGI->new;
my $email = $q->param('email');
my $password = $q->param('password');
my $username;

my $dbh = get_db_connection;

if (!@error) {
    $username = $dbh->selectrow_array("select player from email where address = lower(?)", {}, $email);

    if (!$username) {
        push @error, "The email address is not registered";
    }
}

if (!@error) {
    my $secret = get_secret $dbh;

    my $salt = en_base64 (join '', map { chr int rand 256} 1..16);
    my $hashed_password = bcrypt($password, 
                                 '$2a$08$'.$salt);
    my $token = encrypt_validation_token $secret, $username, $email, $hashed_password;
    my $url = sprintf "http://terra.snellman.net/validate-reset/%s", $token;

    my $smtp = Net::SMTP->new('localhost', ( Debug => 0 ));

    $smtp->mail("www-data\@terra.snellman.net");
    if (!$smtp->to($email)) {
        push @error, "Invalid email address";
    } else {
        $smtp->data();
        $smtp->datasend("To: $email\n");
        $smtp->datasend("From: noreply+registration\@terra.snellman.net\n");
        $smtp->datasend("Subject: Password reset for Terra Mystica\n");
        $smtp->datasend("\n");
        $smtp->datasend("Username: $username\n");
        $smtp->datasend("\n");
        $smtp->datasend("To reset your password, use the following link:\n");
        $smtp->datasend("  $url\n");
        $smtp->dataend();
    }

    $smtp->quit;
}

print encode_json {
    error => \@error,
};
