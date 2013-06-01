use Digest::SHA1 qw(sha1_hex);
use File::Slurp qw(read_file);

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

1;
