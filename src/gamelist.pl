#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use JSON;

use db;
use editlink;
use rlimit;
use natural_cmp;
use session;

my $q = CGI->new;

ensure_csrf_cookie $q;

my $dbh = get_db_connection;
my $mode = $q->param('mode') // 'all';
my $status = $q->param('status') // 'running';

my %res = ( error => '');
my %status = (finished => 1, running => 0);

sub add_sorted {
    $res{games} = [ sort {
                        $b->{action_required} <=> $a->{action_required} or
                        $a->{finished} <=> $b->{finished} or
                        ($a->{seconds_since_update} // 1e12) <=> ($b->{seconds_since_update} // 1e12) or
                        natural_cmp $a->{id}, $b->{id};
                    } @_
        ];
}

sub role_link {
    my ($game, $role, $write_id) = @_;
    if ($role eq 'admin') {
        "/edit/$write_id";
    } else {
        edit_link_for_faction $dbh, $write_id, $role;
    }
}

if ($mode eq 'all') {
    my @ids = $dbh->selectall_arrayref(
        "select id,finished,round from game");
    add_sorted map {
        { id => $_->[0],
          role => 'view',
          link => "/game/".$_->[0],
          finished => $_->[1] ? 1 : 0,
          action_required => 0,
          round => $_->[2],
        }
    } @{$ids[0]};
} elsif ($mode eq 'user' or $mode eq 'admin' or $mode eq 'other-user') {
    my $user = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');
    if ($mode eq 'other-user') {
        $user = $q->param("args");
    } else {
        verify_csrf_cookie_or_die $q;
    }

    if (!defined $user) {
        $res{error} = "Not logged in <a href='/login/'>(login)</a>"
    } else {
        my @roles = $dbh->selectall_arrayref(
            "select game, faction, game.write_id, game.finished, action_required, (extract(epoch from now() - game.last_update)) as time_since_update, vp, rank, (select faction from game_role as gr2 where gr2.game = gr1.game and action_required limit 1) as waiting_for, leech_required, game.round  from game_role as gr1 left join game on game=game.id where email in (select address from email where player = ? and game.finished = ? and (gr1.faction = 'admin') = ?)",
            {}, $user, $status{$status}, 1*!!($mode eq 'admin'));
        add_sorted map {
            { id => $_->[0],
              role => $_->[1],
              link => ($mode eq 'other-user' ? "/game/$_->[0]" : role_link(@{$_})),
              finished => $_->[3] ? 1 : 0,
              action_required => $_->[4] || $_->[9] || 0,
              seconds_since_update => $_->[5],
              vp => $_->[6],
              rank => $_->[7],
              waiting_for => $_->[8],
              round => $_->[10]
            }
        } @{$roles[0]};
    }
} elsif ($mode eq 'open') {
    my $user = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

    if (!defined $user) {
        $res{error} = "Not logged in <a href='/login/'>(login)</a>"
    } else {
        my $games = $dbh->selectall_arrayref(
            "select game.id, game.player_count, game.wanted_player_count, game.description from game where game.wanted_player_count is not null and game.player_count != game.wanted_player_count",
            { Slice => {} },
            );
        $res{games} = $games;
    }
}

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "Connection: close\r\n";
print "\r\n";

print encode_json \%res;

$dbh->disconnect();
