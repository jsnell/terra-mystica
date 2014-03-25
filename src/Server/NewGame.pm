use strict;

package Server::NewGame;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use DB::Game;
use DB::SaveGame;
use DB::UserValidate;
use Email::Notify;
use Server::Session;

method handle($q) {
    my $dbh = get_db_connection;

    $self->no_cache();
    verify_csrf_cookie_or_die $q, $self;

    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');
    if (!$username) {
        my $out = {
            error => ["Login required"],
            link => "/login/#required",
        };
        $self->output_json($out);
        return;
    }

    eval {
        $self->make_game($dbh, $q, $username);
    }; if ($@) {
        my $out = {
            error => [$@],
        };
        $self->output_json($out);
        return;
    }
}

sub error {
    die "$_[0]\n"
}

method make_game($dbh, $q, $username) {

    my $gameid = $q->param('gameid');
    if (!$gameid) {
        error "No game name";
    }

    if ($gameid =~ /([^A-Za-z0-9])/) {
        error "Invalid character in game id '$1'";
    }

    my $game_type = $q->param("game-type");
    my @players = ();
    my $player_count = undef;
    my %blacklist = map { ($_ => 1) } qw(filgalaxy999);

    if ($game_type eq 'private') {
        if ($blacklist{$username}) {
            die "Sorry, your have been banned from creating private games.\n";
        }

        my $players = $q->param('players');
        @players = grep {
            /\S/;
        } map {
            s/^\s*|\s*$//g;
            $_;
        } split /[\n\r]+/, $players;
    } elsif ($game_type eq 'public') {
        $player_count = $q->param('player-count');
        if ($player_count < 2 or $player_count > 5) {
            error "Invalid player count $player_count";
        }
        @players = ($username);
    } else {
        error "Invalid game type '$game_type'";
    }

    begin_game_transaction $dbh, $gameid;

    eval {
        @players = map {
            my $player = $_;
            my $username;
            my $email;
            if ($player =~ /\@/) {
                $username = check_email_is_registered $dbh, $player;
                $email = $player;
            } else {
                ($username, $email) = check_username_is_registered $dbh, $player;
            }
            { email => $email, username => $username }
        } @players;
    }; if ($@) {
        error $@;
    }

    if (game_exists $dbh, $gameid) {
        error "Game $gameid already exists";
    }

    my ($email) = $dbh->selectrow_array("select address from email where player = ? and is_primary", {}, $username);

    my @options = $q->param('game-options');

    eval {
        my $write_id = create_game $dbh, $gameid, $email, [@players], $player_count, @options;

        my $description = $q->param('description');
        if ($description) {
            $dbh->do("update game set description=? where id=?",
                     {},
                     $description,
                     $gameid);
        }

        if ($game_type eq 'private') {
            notify_game_started $dbh, {
                name => $gameid,
                options => { map { ($_ => 1) } @options },
                players => [ values %{get_game_factions($dbh, $gameid)} ],
            }
        }

        my $out = {
            error => [],
            link => "/edit/$write_id"
        };
        $self->output_json($out);
    }; if ($@) {
        error $@;
    }

    finish_game_transaction $dbh;
}

1;

