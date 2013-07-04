#!/usr/bin/perl -w

use CGI qw(:cgi);
use Crypt::CBC;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);
use DBI;
use JSON;
use Net::SMTP;

use secret;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my @error = ();

my $q = CGI->new;
my $username = $q->param('username');
my $email = $q->param('email');
my $password = $q->param('password1');

if ($username =~ /([^A-Za-z0-9._-])/) {
    push @error, "Invalid character in username '$1'"
}

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1 });

if (!@error) {
    my ($username_in_use) = $dbh->selectrow_array("select count(*) from player where lower(username) = lower(?)", {}, $username);
    my ($email_in_use) = $dbh->selectrow_array("select count(*) from email where lower(address) = lower(?)", {}, $email);

    if ($username_in_use) {
        push @error, "The username is already in use";
    }
    
    if ($email_in_use) {
        push @error, "The email address is already registered";
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
        $url = sprintf "http://terra.snellman.net/validate/%s", $token;
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
        $smtp->datasend("Subject: Account activation for Terra Mystica\n");
        $smtp->datasend("\n");
        $smtp->datasend("To activate your account, use the following link:\n");
        $smtp->datasend("  $url\n");
        $smtp->dataend();
    }

    $smtp->quit;
}

print encode_json {
    error => \@error,
};
