use Digest::SHA1 qw(sha1_hex);
use Crypt::Eksblowfish::Bcrypt qw(en_base64);

use secret;

sub session_token {
    my ($dbh, $username, $seed) = @_;
    $seed = substr($seed . "0"x8, 0, 8);

    my $secret = get_secret $dbh;
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

sub read_urandom_string_base64 {
    my $chars = shift;

    open my $f, "</dev/urandom";
    my $data = '';

    read $f, $data, $chars;

    close $f;

    substr en_base64($data), 0, $chars;
}

sub ensure_csrf_cookie {
    my $q = shift;
    if (!$q->cookie("csrf-token")) {
        my $y = 86400*365;
        my $r = read_urandom_string_base64 8;
        print "Set-Cookie: csrf-token=$r; Path=/; Max-Age=$y\r\n";
    }
}

sub verify_csrf_cookie_or_die {
    my $q = shift;
    my $cookie_token = $q->cookie("csrf-token");
    my $param_token = $q->param("csrf-token");
    
    if (!defined $cookie_token or
        !defined $param_token or
        $cookie_token ne $param_token) {
        print STDERR "CSRF verification failure [$cookie_token] [$param_token]\n";
        print "Status: 403\r\n";
        ensure_csrf_cookie $q;
        print "\r\n";
        exit 1;
    }
}

1;
