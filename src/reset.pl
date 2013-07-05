#!/usr/bin/perl -w

use CGI qw(:cgi);
use Crypt::CBC;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);
use JSON;
use Net::SMTP;

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
    my $data = join "\t", ($username, $email, $hashed_password);
    my $url;

    do {
        my $iv = Crypt::CBC->random_bytes(8);
        my $cipher = Crypt::CBC->new(-key => $secret,
                                     -iv => $iv,
                                     -blocksize => 8,
                                     -header => 'randomiv',
                                     -cipher => 'Blowfish');
        my $token = en_base64 $cipher->encrypt($data);
        $url = sprintf "http://terra.snellman.net/validate-reset/%s", $token;
        # Continue until the URL ends in a non-special character, to
        # reduce the chances of the link being mis-.
    } while ($url !~ /[A-Za-z0-9]$/);

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
