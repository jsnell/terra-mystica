use strict;
no indirect;

package Server::EditGame;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use Digest::SHA qw(sha1_hex);

use DB::Chat;
use DB::Connection;
use DB::EditLink;
use DB::Game;
use Server::Session;
use Util::SiteConfig;

has 'mode' => (is => 'ro', required => 1);

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

    eval {
        $self->check_user_is_admin($dbh, $read_id, $username);
        $self->check_user_is_not_deadbeat($dbh, $read_id, $username);
    }; if ($@) {
        $self->output_json({ error => [ $@ ] });
        return;
    }

    if ($self->mode() eq 'content') {
        $self->edit_content($dbh, $q, $read_id, $write_id, $username);
    } elsif ($self->mode() eq 'status') {
        $self->edit_status($dbh, $q, $read_id, $write_id, $username);
    }
}

method check_user_is_admin($dbh, $read_id, $username) {
    my ($game_admin) = $dbh->selectrow_array("select admin_user from game where id=?",
                                             { Slice => {} },
                                             $read_id);

    if ($username ne $game_admin and
        $username ne $config{site_admin_username}) {
        die "Sorry, it appears you're not the game admin.\n"
    }
}

method check_user_is_not_deadbeat($dbh, $read_id, $username) {
    my ($dropped) = $dbh->selectall_arrayref("select faction_player from game_role where game=? and dropped",
                                             { Slice => {} },
                                             $read_id);
    for my $record (@{$dropped}) {
        if ($record->{faction_player} &&
            $username eq $record->{faction_player}) {
            die "Sorry, you're no longer allowed to admin this game\n"
        }
    }

    my %blacklist = map { ($_ => 1) } @{$config{blacklist}};
    if ($blacklist{$username}) {
        die "Sorry, admin functionality disabled due to abuse.\n";
    }
}

method edit_content($dbh, $q, $read_id, $write_id, $username) {
    my ($prefix_data, $data) = get_game_content $dbh, $read_id, $write_id;
    my $players = get_game_players($dbh, $read_id);
    my $metadata = get_game_metadata($dbh, $read_id);

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, "$prefix_data\n$data" ],
        faction_info => get_game_factions($dbh, $read_id),
        players => $players,
        metadata => $metadata,
    };

    # Development hack
    if ($username eq $config{site_admin_username}) {
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

method edit_status($dbh, $q, $read_id, $write_id, $username) {
    my $action = $q->param('action');
    my $res = {
        error => [],
    };

    if ($action eq 'abort') {
        $res->{status} = 'aborted';
        abort_game $dbh, $write_id;
        insert_chat_message($dbh, $read_id,
                            'admin',
                            "Game was aborted by $username",
                            '');
    } elsif ($action eq 'unabort') {
        $res->{status} = 'restarted';
        unabort_game $dbh, $write_id;
        insert_chat_message($dbh, $read_id,
                            'admin',
                            "Game was restarted by $username",
                            '');
    } else {
        $res->{status} = 'error';
        $res->{error} = [ "Invalid action '$action'" ];
    }

    $self->output_json($res);
}

1;
