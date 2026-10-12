use strict;

package Util::CryptUtil;
use Exporter::Easy (EXPORT => [ 'encrypt_validation_token',
                                'shared_iv_cipher',
                                'read_urandom_string_base64',
                                'decrypt_validation_token' ]);

use Crypt::CBC;
use Crypt::Eksblowfish::Bcrypt qw(en_base64 de_base64);
use Digest::MD5 qw(md5);
use Digest::SHA qw(sha1_base64);

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

sub decrypt_validation_token {
    my ($secret, $token) = @_;

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -header => 'randomiv',
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(de_base64 $token);
    my @data = split /\t/, $data;

    my $token_csum = pop @data;
    my $expect_csum = sha1_base64 join "\t", @data;

    if ($token_csum ne $expect_csum) {
        die "Checksum mismatch: $expect_csum $token_csum\n";
    }

    (@data, $token_csum);
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
