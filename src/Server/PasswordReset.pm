use strict;

package Server::PasswordReset;

use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);
use Moose;
use Method::Signatures::Simple;
use Net::SMTP;

use Bytes::Random::Secure qw(random_bytes);
use DB::Connection;
use DB::Secret;
use DB::UserValidate;
use DB::Validation;
use Server::Session;
use Server::Server;
use Util::CryptUtil;
use Util::PasswordQuality;
use Util::SiteConfig;

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
    my $password_again = $q->param('password_again');
    my $username;

    if (!@error) {
        if ($password ne $password_again) {
            push @error, "The two passwords you've entered are different. Please try again."
        }
    }

    if (!@error) {
        $username = $dbh->selectrow_array("select player from email where address = lower(?)", {}, $email);

        if (!$username) {
            push @error, "The email address is not registered";
        }
    }

    if (!@error) {
        my ($reason) = password_too_weak $username, $password;
        if ($reason) {
            push @error, "Bad password: $reason\n";
        }
    }

    if (!@error) {
        my $secret = get_secret $dbh;

        my $salt = en_base64 (join '', map { chr int rand 256} 1..16);
        my $hashed_password = bcrypt($password, 
                                     '$2a$08$'.$salt);
        my $data = {
            username => $username,
            email => $email,
            hashed_password => $hashed_password
        };
        my $token = insert_to_validate $dbh, $data;

        my $url = sprintf "https://$config{domain}/app/reset/validate/%s", $token;

        my $smtp = Net::SMTP->new('localhost', ( Debug => 0 ));

        $smtp->mail("www-data\@$config{email_domain}");
        if (!$smtp->to($email)) {
            push @error, "Invalid email address";
        } else {
            $smtp->data();
            $smtp->datasend("To: $email\n");
            $smtp->datasend("From: noreply+registration\@$config{email_domain}\n");
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

    eval {
        my @data = ();
        my $payload = fetch_validate_payload $dbh, $token;
        @data = ($payload->{username}, $payload->{email},
                 $payload->{hashed_password});

        $self->reset_password($dbh, @data);
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
