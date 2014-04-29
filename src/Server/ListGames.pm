use strict;

package Server::ListGames;

use Moose;
use Method::Signatures::Simple;
use Server::Server;

extends 'Server::Server';

use CGI qw(:cgi);

use DB::Connection;
use DB::Game;
use DB::EditLink;
use Util::NaturalCmp;
use Server::Session;

has 'mode' => (is => 'ro', required => 1);

method handle($q, $path_suffix) {
    $self->no_cache();
    $self->set_header("Connection", "Close");

    ensure_csrf_cookie $q, $self;

    my $dbh = get_db_connection;
    my $mode = $q->param('mode') // $self->mode() // 'all';
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
    } elsif ($mode eq 'by-pattern') {
        $self->allow_cross_domain();
        $res{games} = get_game_list_by_pattern $dbh, $path_suffix;
        $res{error} = [];
    }

    $self->output_json({%res});
}

method open_games($dbh, $res, $user) {
    if (!defined $user) {
        $res->{error} = "Not logged in <a href='/login/'>(login)</a>";
    } else {
        $res->{games} = get_open_game_list $dbh;
    }
}

method user_games($dbh, $res, $user, $mode, $status, $admin) {
    if (!defined $user) {
        $res->{error} = "Not logged in <a href='/login/'>(login)</a>"
    } else {
        $res->{games} = get_user_game_list $dbh, $user, $mode, $status, $admin;
    }
}

1;
