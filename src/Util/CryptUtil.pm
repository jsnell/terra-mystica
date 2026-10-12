use strict;

package Util::CryptUtil;
use Exporter::Easy (EXPORT => [ 'shared_iv_cipher',
                                'read_urandom_string_base64' ]);

use Crypt::CBC;
use Crypt::Eksblowfish::Bcrypt qw(en_base64);
use Digest::MD5 qw(md5);

# Headerless Blowfish-CBC with a fixed IV. Crypt::CBC 3.x would derive
# the key from the passphrase using a random salt in this mode, so
# derive it here instead, the same way Crypt::CBC 2.x did.
sub shared_iv_cipher {
    my ($secret, $iv) = @_;

    my $keysize = 56;
    my $key = md5($secret);
    while (length($key) < $keysize) {
        $key .= md5($key);
    }

    Crypt::CBC->new(-key => substr($key, 0, $keysize),
                    -literal_key => 1,
                    -keysize => $keysize,
                    -iv => $iv,
                    -add_header => 0,
                    -cipher => 'Blowfish');
}

sub read_urandom_string_base64 {
    my $chars = shift;

    open my $f, "</dev/urandom";
    my $data = '';

    read $f, $data, $chars;

    close $f;

    substr en_base64($data), 0, $chars;
}

1;
