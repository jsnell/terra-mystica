use strict;

package Server::EditGame;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA1 qw(sha1_hex);

use DB::Connection;
use DB::EditLink;
use DB::Game;
use Server::Session;

method handle($q) {
    $self->no_cache();

    my $write_id = $q->param('game');
    $write_id =~ s{.*/}{};
    $write_id =~ s{[^A-Za-z0-9_]}{}g;

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
       
    my ($read_id) = $write_id =~ /(.*?)_/g;
    my ($prefix_data, $data) = get_game_content $dbh, $read_id, $write_id;
    my $players = get_game_players($dbh, $read_id);
    my $metadata = get_game_metadata($dbh, $read_id);

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, "$prefix_data\n$data" ],
        faction_info => get_game_factions($dbh, $read_id),
        players => $players,
    };

    # Development hack
    if ($username eq 'jsnell') {
        for my $faction (values %{$res->{factions}}) {
            $faction->{edit_link} = edit_link_for_faction $dbh, $write_id, $faction->{name};
        }
    }

    my $out = {
        data => $data,
        error => [],
        hash => sha1_hex($data),
        action_required => $res->{action_required},
        players => $players,
        factions => $res->{factions},
        metadata => $metadata,
    };

    $self->output_json($out);
}

1;
