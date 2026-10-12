use strict;

package DB::EditLink;
use Exporter::Easy (EXPORT => [ 'edit_link_for_faction' ]);

use DB::Secret;
use Encode;
use Util::CryptUtil;

sub edit_link_for_faction {
    my ($dbh, $id, $faction_name) = @_;

    my ($secret, $iv) = get_secret $dbh;

    my ($game, $game_secret) = ($id =~ /(.*)_(.*)/g);
    $game_secret = pack "h*", $game_secret;
    my $cipher = shared_iv_cipher($secret, $iv);
    my $data = "$game_secret" ^ encode('iso-8859-1', "$faction_name");
    my $token = unpack 'h*', $cipher->encrypt($data);
    
    return "/faction/$game/".($faction_name)."/$token";
}

1;
