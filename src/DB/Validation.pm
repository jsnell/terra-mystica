use strict;

package DB::Validation;
use Exporter::Easy (EXPORT => [ 'insert_to_validate', 'fetch_validate_payload' ]);

use Bytes::Random::Secure qw(random_string_from);
use JSON;

sub insert_to_validate {
    my ($dbh, $payload) = @_;

    my $random = Bytes::Random::Secure->new(
        Bits        => 512,
        NonBlocking => 1,
    );
    my $token = $random->string_from('ABCDEFGHIJKLMNOPQRSTUVXYZ'.
                                     'abcdefghijklmnopqrstuvxyz'.
                                     '0123456789',
                                     16); 

    $dbh->do(
        "insert into to_validate (token, payload) values (?, ?)",
        {},
        $token, encode_json $payload);

    $token;
}

sub fetch_validate_payload {
    my ($dbh, $token) = @_;

    my @payload = $dbh->selectrow_array(
        "select payload from to_validate where token=?",
        { Slice => {} },
        $token);

    if (!@payload) {
        die "Invalid validation token\n";
    }

    $dbh->do("update to_validate set executed=true where token=?",
             {},
             $token);

    decode_json $payload[0];
}

1;
