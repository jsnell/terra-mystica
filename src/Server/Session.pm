package Server::Session;
use Exporter::Easy (EXPORT => [ 'session_token',
                                'username_from_session_token',
                                'ensure_csrf_cookie',
                                'verify_csrf_cookie_or_die']);

use Digest::SHA qw(sha1_hex);
use Crypt::Eksblowfish::Bcrypt qw(en_base64);

use DB::Secret;
use Util::CryptUtil;

sub session_token {
    my ($dbh, $username, $seed) = @_;
    $seed =~ s{/}{_}g;
    $seed = substr($seed . "0"x8, 0, 8);

    my ($secret) =
        $dbh->selectrow_array("select password from player where username=?",
                              {},
                              $username);
    if (!$secret) {
        die "Can't create session token for $username\n";
    }
    my $head = "$seed/$username";
    my $hash = sha1_hex "$head/$secret";
    "$head/$hash"
}

sub username_from_session_token {
    my ($dbh, $token) = @_;
    return if !$token;

    my ($seed, $username, $hash) = (split m{/}, $token);
    my $expected_token = session_token $dbh, $username, $seed;

    if ($expected_token eq $token) {
        $username;
    } else {
        undef;
    }
}

sub ensure_csrf_cookie {
    my ($q, $server) = @_;

    die "Invalid call to ensure_csrf_cookie" if !$server;

    if (!$q->cookie("csrf-token")) {
        my $y = 86400*365;
        my $r = read_urandom_string_base64 8;
        $server->set_cookie("csrf-token",
                            $r, ["Path=/", "Max-Age=$y"]);
    }
}

sub verify_csrf_cookie_or_die {
    my ($q, $server) = @_;
    my $cookie_token = $q->cookie("csrf-token");
    my $param_token = $q->param("csrf-token");

    die "Invalid call to verify_csrf_cookie_or_die" if !$server;

    if (!defined $cookie_token or
        !defined $param_token or
        $cookie_token ne $param_token) {
        $cookie_token //= 'undefined';
        $param_token //= 'undefined';
        # print STDERR "CSRF verification failure [$cookie_token] [$param_token]\n";
        # print STDERR ("  User: ", $q->cookie('session-username'),
        #               "\n    UA: ", $q->user_agent(),
        #               "\n  Path: $0\n");
        $server->status(403);
        if ($cookie_token eq 'undefined') {
            ensure_csrf_cookie $q, $server;
        }
        die "CSRF token validation error";
    }
}

1;
