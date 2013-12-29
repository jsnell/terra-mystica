use strict;

package Server::Alias;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Net::SMTP;

use DB::Connection;
use DB::Secret;
use Server::Session;
use Util::CryptUtil;

has 'mode' => (is => 'ro', required => 1);

method handle($q, $suffix) {
    $self->no_cache();
    my $dbh = get_db_connection;
    my $mode = $self->mode();

    if ($mode eq 'validate') {
        $self->validate_alias($q, $dbh, $suffix);
    } elsif ($mode eq 'request') {
        $self->request_alias($q, $dbh);
    } else {
        die "Unknown mode $mode";
    }
}

method request_alias($q, $dbh) {
    my @error = ();

    my $email = $q->param('email');
    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');

    if (!$username) {
        push @error, "not logged in";
    } else {
        verify_csrf_cookie_or_die $q, $self;
    }

    if (!@error) {
        my ($email_in_use) = $dbh->selectrow_array("select count(*) from email where lower(address) = lower(?)", {}, $email);

        if ($email_in_use) {
            push @error, "The email address is already registered";
        }
    }

    if (!@error) {
        my $secret = get_secret $dbh;

        my $token = encrypt_validation_token $secret, ($username, $email);
        my $url = sprintf "http://terra.snellman.net/alias/validate/%s", $token;

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

    $self->output_json({ error => [@error] });
}

method validate_alias($q, $dbh, $suffix) {
    my $token = $suffix // $q->param('token');

    my ($secret, $iv) = get_secret;
    eval {
        $self->add_alias($dbh, decrypt_validation_token $secret, $token);
        $self->output_html("<h3>Email alias registered</h3>");
    }; if ($@) {
        print STDERR "token: $token\n";
        print STDERR $@;
        $self->output_html("<h3>Validation failed</h3>");
    }
}

method add_alias($dbh, $user, $email) {
    my ($already_done) = $dbh->selectrow_array("select count(*) from email where lower(address) = lower(?) and player = ?", {}, $email, $user);

    if (!$already_done) {
        $dbh->do('begin');
        $dbh->do('insert into email (address, player, validated, is_primary) values (lower(?), ?, ?, false)',
                 {}, $email, $user, 1);
        $dbh->do('commit');
    }
}

1;
