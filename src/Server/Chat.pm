use strict;

package Server::Chat;

use Moose;
use Server::Server;

extends 'Server::Server';

use Crypt::CBC;
use DB::Connection;
use DB::Secret;
use Email::Notify;
use Server::Security;
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

    my $faction_name = $q->param('faction');
    my $faction_key = $q->param('faction-key');
    my $add_message = $q->param('add-message');
    my $turn = $q->param('turn');
    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');

    my %res = ( error => [] );

    eval {
        if ($faction_key eq '') {
            get_write_id_for_user $dbh, $username, $id, $faction_name;
        } else {
            verify_key $dbh, $id, $faction_key, $faction_name;
        }
        if (defined $add_message) {
            $dbh->do('begin');
            $dbh->do(
                "insert into chat_message (faction, game, message, posted_on_turn) values (?, ?, ?, ?)",
                {},
                $faction_name,
                $id,
                $add_message,
                $turn);
            $dbh->do('commit');

            my $factions = $dbh->selectall_arrayref(
                "select game_role.faction as name, email, player.displayname from game_role left join email on email.address = game_role.email left join player on email.player = player.username where game = ? and email is not null",
                { Slice => {} },
                $id);

            notify_new_chat $dbh, {
                name => $id,
                factions => { map { ($_->{name}, $_) } @{$factions} }
            }, $faction_name, $add_message;
        }

        my $rows = $dbh->selectall_arrayref(
            "select faction, message, extract(epoch from now() - posted_at) as message_age, posted_on_turn from chat_message where game = ? order by posted_at asc",
            { Slice => {} },
            $id);
        
        if ($username) {
            $dbh->do("begin");
            my $count =
                $dbh->do("update chat_read set last_read = now() where game=? and player=?",
                         {},
                         $id,
                         $username);
            if ($count == 0) {
                $dbh->do("insert into chat_read (last_read, game, player) values (now(), ?, ?)",
                         {},
                         $id,
                         $username);
            }
            $dbh->do("commit");
        }

        $res{messages} = $rows;
    }; if ($@) {
        $res{error} = ["$@"];
    }

    $self->output_json(\%res);
}
