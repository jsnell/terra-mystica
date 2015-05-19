use strict;

package DB::EditLink;
use Exporter::Easy (EXPORT => [ 'edit_link_for_faction' ]);

use Crypt::CBC;
use DB::Secret;
use Encode;

sub edit_link_for_faction {
    my ($dbh, $id, $faction_name) = @_;

    my ($secret, $iv) = get_secret $dbh;

    my ($game, $game_secret) = ($id =~ /(.*)_(.*)/g);
    $game_secret = pack "h*", $game_secret;
    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = "$game_secret" ^ encode('iso-8859-1', "$faction_name");
    my $token = unpack 'h*', $cipher->encrypt($data);
    
    return "/faction/$game/".($faction_name)."/$token";
}

1;
