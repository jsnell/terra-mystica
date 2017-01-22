use strict;

package Server::SaveGame;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA qw(sha1_hex);

use DB::Chat;
use DB::Connection;
use DB::Game;
use DB::SaveGame;
use DB::UserValidate;
use Text::Diff qw(diff);
use Server::Session;
use tracker;

method handle($q) {
    $self->no_cache();

    my $dbh = get_db_connection;

    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');
    if (!defined $username) {
        my $out = {
                error => ["Not logged in"],
                location => "/login/",
        };
        $self->output_json($out);
        return;
    }    

    my $write_id = $q->param('game');
    $write_id =~ s{.*/}{};
    $write_id =~ s{[^A-Za-z0-9_]}{}g;
    my ($read_id) = $write_id =~ /(.*)_/g;

    my $orig_hash = $q->param('orig-hash');
    my $new_content = $q->param('content');

    begin_game_transaction $dbh, $read_id;

    my ($prefix_content, $orig_content) =
        get_game_content $dbh, $read_id, $write_id;

    my $res = {};

    if (sha1_hex($orig_content) ne $orig_hash) {
        print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
        $res->{error} = [
            "Someone else made changes to the game. Please reload\n"
            ];
    } else {
        $res = evaluate_and_save $dbh, $read_id, $write_id, $prefix_content, $new_content;
    }

    if (@{$res->{error}}) {
        $dbh->do("rollback");
    } else {
        finish_game_transaction $dbh;

        my $a = "$orig_content\n";
        my $b = "$new_content\n";
        $a =~ s/\r//g;
        $b =~ s/\r//g;
        $a =~ s/\n+/\n/g;
        $b =~ s/\n+/\n/g;

        if ($a ne $b) {
            my $diff = diff \$a, \$b, { CONTEXT => 1 };

            insert_chat_message($dbh, $read_id,
                                'admin',
                                "Game was edited by $username:\n$diff",
                                "round $res->{round}, turn $res->{turn}");
        }
    }

    my $out = {
        error => $res->{error},
        hash => sha1_hex($new_content),
        action_required => $res->{action_required},
        factions => {
            map {
                ($_->{name}, { display => $_->{display}, color => $_->{color} })
            } values %{$res->{factions}}
        },
        players => get_game_players($dbh, $read_id)
    };
    $self->output_json($out);
}

1;
