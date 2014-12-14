use strict;

package DB::Chat;
use Exporter::Easy (EXPORT => [ 'insert_chat_message']);

sub insert_chat_message {
    my ($dbh, $game_id, $faction_name, $message, $posted_on_turn) = @_;
    
    $dbh->do(
        "insert into chat_message (faction, game, message, posted_on_turn) values (?, ?, ?, ?)",
        {},
        $faction_name,
        $game_id,
        $message,
        $posted_on_turn);
}

1;
