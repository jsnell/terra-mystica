use strict;
no indirect;

package Server::ViewGame;

use Moose;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection qw(get_db_connection);
use DB::Game;
use Server::Security;
use Server::Session;
use Util::CryptUtil;
use Util::ServerUtil;
use tracker;

method handle($q) {
    $self->no_cache();

    my $id = $q->param_or_die('game');
    $id =~ s{.*/}{};
    $id =~ s{[^A-Za-z0-9_]}{}g;
    my $max_row = $q->param('max-row');
    my $preview = $q->param('preview');
    my $preview_faction = $q->param('preview-faction');

    my $dbh = get_db_connection;
    my $username = username_from_session_token(
        $dbh,
        $q->cookie('session-token') // '');

    if (!game_exists($dbh, $id)) {
        $self->status(404);
        $self->output_json({ error => [ "Unknown game: $id" ] });
        log_with_request $q, "Unknown game: $id";
        return;
    }

    my @rows = get_game_commands $dbh, $id;

    if (defined $preview) {
        if ($preview_faction =~ /^player/) {
            if ($preview =~ s/(setup (\w+))//i) {
                push @rows, "$1\n";
                $preview_faction = lc $2;
                push @rows, (map { "$preview_faction: $_" } grep { /\S/ } split /\n/, $preview);
            }
        } else {
            push @rows, (map { "$preview_faction: $_" } split /\n/, $preview);
        }
    }

    my $players = get_game_players($dbh, $id);
    my $metadata = get_game_metadata($dbh, $id);

    my $res = terra_mystica::evaluate_game {
        rows => \@rows,
        faction_info => get_game_factions($dbh, $id),
        players => $players,
        metadata => $metadata,
        max_row => $max_row
    };
    eval {
        ($res->{chat_message_count},
         $res->{chat_unread_message_count}) = get_chat_count($dbh, $id, $username);
    };
    $res->{metadata} = get_game_metadata $dbh, $id;

    $self->output_json($res);
};

1;
