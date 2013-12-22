use strict;

package Server::Plan;

use Moose;
use Server::Server;

extends 'Server::Server';

use Crypt::CBC;
use DB::Connection;
use DB::Secret;
use Server::Session;

sub verify_key {
    my ($dbh, $id, $faction_key, $faction_name) = @_;
    my ($secret, $iv) = get_secret $dbh;

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);

    my $write_id = "${id}_$game_secret";
    my $valid = $dbh->selectrow_array("select count(*) from game where write_id=?", {}, $write_id);

    die "Invalid faction key\n" if !$valid;
};

sub handle {
    my ($self, $q) = @_;
    $self->no_cache();

    my $dbh = get_db_connection;

    my $id = $q->param('game');
    $id =~ s{.*/}{};
    $id =~ s{[^A-Za-z0-9_]}{}g;

    my $faction_name = $q->param('preview-faction');
    my $faction_key = $q->param('faction-key');
    my $set_note = $q->param('set-note');

    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');
    my %res = (error => []);

    eval {
        if (!$username) {
            die "Not logged in\n";
        }

        my $faction_player = $dbh->selectrow_array(
            "select email.player from game_role left join email on game_role.email=email.address where game_role.game=? and faction=?",
            {},
            $id,
            $faction_name);

        if ($username ne $faction_player) {
            die "Trying to read another player's notes?\n";
        }

        verify_key $dbh, $id, $faction_key, $faction_name;
        if (defined $set_note) {
            $res{note} = $set_note;

            $dbh->do('begin');
            my $res = $dbh->do(
                "delete from game_note where faction = ? and game = ?",
                {},
                $faction_name,
                $id);
            $res = $dbh->do(
                "insert into game_note (faction, game, note, author) values (?, ?, ?, ?)",
                {},
                $faction_name,
                $id,
                $set_note,
                $username);
            $dbh->do('commit');
        } else {
            my $rows = $dbh->selectall_arrayref(
                "select note from game_note where faction = ? and game = ? and author = ?",
                {},
                $faction_name,
                $id,
                $username);
            $res{note} = $rows->[0][0];
        }
    }; if ($@) {
        $res{error} = [ "$@" ];
    }

    $self->output_json(\%res);
}


