#!/usr/bin/perl -w

use strict;

use exec_timer;

use CGI qw(:cgi);
use DBI;
use JSON;

use editlink;
use natural_cmp;
use session;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 0, RaiseError => 1});
my $q = CGI->new;
my $mode = $q->param('mode') // 'all';

my %res = ( error => '');

sub add_sorted {
    $res{games} = [ sort {
                        $b->{action_required} <=> $a->{action_required} or
                        $a->{finished} <=> $b->{finished} or
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
    my @ids = $dbh->selectall_arrayref("select id,finished from game");
    add_sorted map {
        { id => $_->[0],
          role => 'view',
          link => "/game/".$_->[0],
          finished => $_->[1] ? 1 : 0,
          action_required => 0,
        }
    } @{$ids[0]};
} elsif ($mode eq 'user') {
    my $user = username_from_session_token $q->cookie('session-token') // '';
    if (!defined $user) {
        $res{error} = "Not logged in"
    } else {
        my @roles = $dbh->selectall_arrayref(
            "select game, faction, game.write_id, game.finished, action_required from game_role left join game on game=game.id where email in (select address from email where player = ?)",
            {}, $user);
        add_sorted map {
            { id => $_->[0],
              role => $_->[1],
              link => role_link(@{$_}),
              finished => $_->[3] ? 1 : 0,
              action_required => $_->[4],
            }
        } @{$roles[0]};
    }
}

print encode_json \%res;

$dbh->disconnect();
