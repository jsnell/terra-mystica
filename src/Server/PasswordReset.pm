use strict;

package Server::PasswordReset;

use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);
use Moose;
use Method::Signatures::Simple;
use Net::SMTP;

use DB::Connection;
use DB::Secret;
use DB::UserValidate;
use Server::Session;
use Server::Server;
use Util::CryptUtil;

extends 'Server::Server';

has 'mode' => (is => 'ro', required => 1);

method handle($q, $suffix) {
    $self->no_cache();
    my $dbh = get_db_connection;
    my $mode = $self->mode();

    if ($mode eq 'validate') {
        $self->validate_reset($q, $dbh, $suffix);
    } elsif ($mode eq 'request') {
        $self->request_reset($q, $dbh);
    } else {
        die "Unknown mode $mode";
    }
}

method request_reset($q, $dbh) {
    my @error = ();

    my $email = $q->param('email');
    my $password = $q->param('password');
    my $username;

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
        my $url = sprintf "http://terra.snellman.net/reset/validate/%s", $token;

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

    $self->output_json({ error => [@error] });
}

method validate_reset($q, $dbh, $suffix) {
    my $token = $suffix // $q->param('token');

    my ($secret, $iv) = get_secret;
    eval {
        $self->reset_password($dbh, decrypt_validation_token $secret, $token);
        $self->output_html("<h3>The password has been reset</h3>");
    }; if ($@) {
        print STDERR "token: $token\n";
        print STDERR $@;
        $self->output_html("<h3>Validation failed</h3>");
    }
}

method reset_password($dbh, $user, $email, $hashed_password) {
    $dbh->do('begin');

    $dbh->do('update player set password=? where username=?',
             {},
             $hashed_password,
             $user);

    $dbh->do('commit');
}

1;
