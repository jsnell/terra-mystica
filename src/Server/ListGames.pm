use strict;

package Server::ListGames;

use Moose;
use MooseX::Method::Signatures;
use Server::Server;

extends 'Server::Server';

use CGI qw(:cgi);

use DB::Connection;
use DB::EditLink;
use Util::NaturalCmp;
use Server::Session;

sub add_sorted {
    my $res = shift;

    $res->{games} = [ sort {
        $b->{action_required} <=> $a->{action_required} or
            $a->{finished} <=> $b->{finished} or
            ($a->{seconds_since_update} // 1e12) <=> ($b->{seconds_since_update} // 1e12) or
            natural_cmp $a->{id}, $b->{id};
                    } @_
        ];
}


sub role_link {
    my ($dbh, $game, $role, $write_id) = @_;
    if ($role eq 'admin') {
        "/edit/$write_id";
    } else {
        edit_link_for_faction $dbh, $write_id, $role;
    }
}

method handle($q) {
    $self->no_cache();
    $self->set_header("Connection", "Close");

    ensure_csrf_cookie $q, $self;

    my $dbh = get_db_connection;
    my $mode = $q->param('mode') // 'all';
    my $status = $q->param('status') // 'running';

    my %res = (error => '');

    if ($mode eq 'user' or $mode eq 'admin' or $mode eq 'other-user') {
        my $user = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');
        if ($mode eq 'other-user') {
            $user = $q->param("args");
        } else {
            verify_csrf_cookie_or_die $q, $self;
        }

        my %status = (finished => 1, running => 0);
        $self->user_games($dbh,
                          \%res,
                          $user,
                          $mode,
                          $status{$status},
                          1*!!($mode eq 'admin'));
    } elsif ($mode eq 'open') {
        my $user = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');
        $self->open_games($dbh, \%res, $user);
    }

    $self->output_json({%res});
}

method open_games($dbh, $res, $user) {
    if (!defined $user) {
        $res->{error} = "Not logged in <a href='/login/'>(login)</a>";
    } else {
        my $games = $dbh->selectall_arrayref(
            "select game.id, game.player_count, game.wanted_player_count, game.description, array(select player from game_player where game_player.game=game.id) as players from game where game.wanted_player_count is not null and game.player_count != game.wanted_player_count and not game.finished",
            { Slice => {} }
            );
        $res->{games} = $games;
    }
}

method user_games($dbh, $res, $user, $mode, $status, $admin) {
    if (!defined $user) {
        $res->{error} = "Not logged in <a href='/login/'>(login)</a>"
    } else {
        my @roles = $dbh->selectall_arrayref(
            "select game, faction, game.write_id, game.finished, action_required, (extract(epoch from now() - game.last_update)) as time_since_update, vp, rank, (select faction from game_role as gr2 where gr2.game = gr1.game and action_required limit 1) as waiting_for, leech_required, game.round, (select count(*) from chat_message where game=game.id and posted_at > (select coalesce((select last_read from chat_read where game=chat_message.game and player=?), '2012-01-01'))) as unread_chat, game.aborted from game_role as gr1 left join game on game=game.id where email in (select address from email where player = ? and (game.finished = ? or (game.finished and last_update > now() - interval '2 days')) and (gr1.faction = 'admin') = ?)",
            {}, $user, $user, $status, $admin);
        add_sorted($res,
                   map {
                       { id => $_->[0],
                         role => $_->[1],
                         link => ($mode eq 'other-user' ? "/game/$_->[0]" : role_link($dbh, @{$_})),
                         finished => $_->[3] ? 1 : 0,
                         action_required => !$_->[12] && ($_->[4] || $_->[9]) || 0,
                         seconds_since_update => $_->[5],
                         vp => $_->[6],
                         rank => $_->[7],
                         waiting_for => $_->[8],
                         round => $_->[10],
                         unread_chat_messages => 1*$_->[11],
                         aborted => $_->[12],
                       }
                   } @{$roles[0]});
    }
}

1;
