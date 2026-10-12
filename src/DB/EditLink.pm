use strict;

package DB::EditLink;
use Exporter::Easy (EXPORT => [ 'edit_link_for_faction',
                                'verify_faction_key' ]);

use DB::Secret;
use Digest::SHA qw(hmac_sha256_hex);
use Util::CryptUtil;

sub faction_key {
    my ($secret, $write_id, $faction_name) = @_;

    my $data = "faction-link\0$write_id\0$faction_name";
    utf8::encode($data);

    substr hmac_sha256_hex($data, $secret), 0, 32;
}

# Links generated before the switch to HMACs. The key is the secret part
# of the write_id xored with the faction name and Blowfish encrypted.
sub legacy_write_id {
    my ($secret, $iv, $read_id, $faction_name, $faction_key) = @_;

    my $game_secret = eval {
        my $cipher = shared_iv_cipher($secret, $iv);
        my $data = $cipher->decrypt(pack "h*", $faction_key);
        unpack("h*", $data ^ $faction_name);
    };

    return undef if !defined $game_secret;
    "${read_id}_$game_secret";
}

sub constant_time_eq {
    my ($a, $b) = @_;

    return 0 if length $a != length $b;

    my $diff = 0;
    $diff |= ord for split //, $a ^ $b;
    $diff == 0;
}

sub edit_link_for_faction {
    my ($dbh, $id, $faction_name) = @_;

    my ($secret) = get_secret $dbh;
    my ($game) = ($id =~ /(.*)_(.*)/g);
    my $token = faction_key $secret, $id, $faction_name;

    return "/faction/$game/".($faction_name)."/$token";
}

# Returns the write_id of the game if the key is valid for the faction,
# dies otherwise.
sub verify_faction_key {
    my ($dbh, $read_id, $faction_name, $faction_key) = @_;

    my ($secret, $iv) = get_secret $dbh;
    my $write_id = $dbh->selectrow_array(
        "select write_id from game where id=?", {}, $read_id);

    die "Invalid faction key\n" if !defined $write_id;

    my $expect_key = faction_key $secret, $write_id, $faction_name;
    return $write_id if constant_time_eq $faction_key, $expect_key;

    my $legacy_write_id = legacy_write_id($secret, $iv, $read_id,
                                          $faction_name, $faction_key);
    if (defined $legacy_write_id and
        constant_time_eq $legacy_write_id, $write_id) {
        print STDERR "Legacy faction key used: game=$read_id faction=$faction_name\n";
        return $write_id;
    }

    die "Invalid faction key\n";
}

1;
