use strict;

package Server::Login;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);

use DB::Connection;
use Server::Session;
use Util::CryptUtil;
use Util::PasswordQuality;
use Util::ServerUtil;

method handle($q) {
    my $form_username = $q->param('username');
    my $password = $q->param('password');

    my $dbh = get_db_connection;

    my ($stored_password, $username) = $dbh->selectrow_array("select password, username from player where lower(username) = lower(?)", {}, $form_username);

    my $match = 0;
    my $invalid_user = 0;

    if (!$stored_password) {
        log_with_request $q, "login: invalid username for $form_username";
        $invalid_user = 1;
    } elsif ($stored_password ne bcrypt($password, $stored_password)) {
        log_with_request $q, "login: invalid password for $form_username";
    } else {
        log_with_request $q, "login: ok for $form_username";
        $match = 1;
    }

    $self->no_cache();

    if ($match && password_too_weak $username, $password) {
        $self->set_header("Set-Cookie", "csrf-token=; Path=/");
        $self->set_header("Set-Cookie", "session-username=; Path=/");
        $self->set_header("Set-Cookie", "session-token=; Path=/; HttpOnly");
        $self->redirect("/forcedreset/");
        log_with_request $q, "login: forced password reset for $form_username"
    } elsif ($match) {
        my $token = session_token $dbh, $username, read_urandom_string_base64 8;
        my $y = 86400*365;
        ensure_csrf_cookie $q, $self;
        $self->set_header("Set-Cookie",
                          "session-username=$username; Path=/; Max-Age=$y");
        $self->set_header("Set-Cookie",
                          "session-token=$token; Path=/; HttpOnly; Max-Age=$y");
        $self->redirect("/");
    } else {
        $self->set_header("Set-Cookie", "csrf-token=; Path=/");
        $self->set_header("Set-Cookie", "session-username=; Path=/");
        $self->set_header("Set-Cookie", "session-token=; Path=/; HttpOnly");
        if ($invalid_user) {
            $self->redirect("/login/#invalid-user");
        } else {
            $self->redirect("/login/#failed");
        }
    }
}

1;

