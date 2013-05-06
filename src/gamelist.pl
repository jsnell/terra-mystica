#!/usr/bin/perl -w

use strict;

use exec_timer;

use CGI qw(:cgi);
use DBI;
use JSON;

use editlink;
use rlimit;
use natural_cmp;
use session;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0, RaiseError => 1});
my $q = CGI->new;
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
        edit_link_for_faction $write_id, $role;
    }
}

if ($mode eq 'all') {
    my @ids = $dbh->selectall_arrayref(
        "select id,finished from game");
    add_sorted map {
        { id => $_->[0],
          role => 'view',
          link => "/game/".$_->[0],
          finished => $_->[1] ? 1 : 0,
          action_required => 0,
        }
    } @{$ids[0]};
} elsif ($mode eq 'user' or $mode eq 'admin') {
    my $user = username_from_session_token $q->cookie('session-token') // '';
    if (!defined $user) {
        $res{error} = "Not logged in <a href='/login/'>(login)</a>"
    } else {
        my @roles = $dbh->selectall_arrayref(
            "select game, faction, game.write_id, game.finished, action_required, (extract(epoch from now() - game.last_update)) as time_since_update, vp, rank, (select faction from game_role as gr2 where gr2.game = gr1.game and action_required limit 1) as waiting_for, leech_required from game_role as gr1 left join game on game=game.id where email in (select address from email where player = ? and game.finished = ? and (gr1.faction = 'admin') = ?)",
            {}, $user, $status{$status}, 1*!!($mode eq 'admin'));
        add_sorted map {
            { id => $_->[0],
              role => $_->[1],
              link => role_link(@{$_}),
              finished => $_->[3] ? 1 : 0,
              action_required => $_->[4] || $_->[9] || 0,
              seconds_since_update => $_->[5],
              vp => $_->[6],
              rank => $_->[7],
              waiting_for => $_->[8]
            }
        } @{$roles[0]};
    }
}

print encode_json \%res;

$dbh->disconnect();
