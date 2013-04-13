use strict;

use Crypt::CBC;
use File::Slurp qw(read_file);

my $secret = read_file("../../data/secret");
my $iv = read_file("../../data/iv");

sub edit_link_for_faction {
    my ($id, $faction_name) = @_;

    my ($game, $game_secret) = ($id =~ /(.*?)_(.*)/g);
    $game_secret = pack "h*", $game_secret;
    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $game_secret ^ $faction_name;
    my $token = unpack "h*", $cipher->encrypt($data);

    return "/faction/$game/".($faction_name)."/$token";
}

1;
