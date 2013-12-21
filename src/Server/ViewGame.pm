use strict;

package terra_mystica::Server::ViewGame;

use Moose;
use MooseX::Method::Signatures;
use Server::Server;

extends 'terra_mystica::Server::Server';

use db;
use game;
use session;
use tracker;

method handle($q) {
    $self->set_header("Cache-Control", "no-cache");

    my $id = $q->param('game');
    $id =~ s{.*/}{};
    $id =~ s{[^A-Za-z0-9]}{}g;
    my $max_row = $q->param('max-row');
    my $preview = $q->param('preview');
    my $preview_faction = $q->param('preview-faction');

    my $dbh = get_db_connection;
    my $username = username_from_session_token(
        $dbh,
        $q->cookie('session-token') // '');

    if (!game_exists $dbh, $id) {
        $self->status(404);
        $self->output_json({ error => [ "Unknown game: $id" ] });
        return;
    }

    my @rows = get_game_commands($dbh, $id);

    if (defined $preview) {
        if ($preview_faction =~ /^player/) {
            if ($preview =~ /(setup \w+)/i) {
                push @rows, "$1\n"; 
            }
        } else {
            push @rows, (map { "$preview_faction: $_" } split /\n/, $preview);
        }
    }

    my $res = terra_mystica::evaluate_game {
        rows => \@rows,
        faction_info => get_game_factions($dbh, $id),
        players => get_game_players($dbh, $id),
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
