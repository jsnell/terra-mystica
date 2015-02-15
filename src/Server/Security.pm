package Server::Security;
use Exporter::Easy (EXPORT => [ 'ensure_user_may_view_game', 'get_write_id_for_user' ]);

sub get_write_id_for_user {
    my ($dbh, $username, $read_id, $faction_name) = @_;

    if (!defined $username) {
        die "Not logged in\n";
    }

    if (!$dbh->selectrow_array("select count(*) from game_role where game=? and faction=? and faction_player=?",
                               {},
                               $read_id,
                               $faction_name,
                               $username)) {
        die "You ($username) don't appear to be the player controlling $faction_name in game $read_id.\n";
    }
    
    return $dbh->selectrow_array("select write_id from game where id=?",
                                 {},
                                 $read_id);
}

1;
