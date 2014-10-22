use strict;
no indirect;

package Server::NewGame;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use DB::Game;
use DB::SaveGame;
use DB::UserInfo;
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

    if (length $gameid > 32) {
        error "game id '$gameid' too long";
    }

    my $game_type = $q->param("game-type");
    my @players = ();
    my $player_count = undef;
    my %blacklist = map { ($_ => 1) } qw();

    if ($game_type eq 'private') {
        if ($blacklist{$username}) {
            die "Sorry, you have been banned from creating private games.\n";
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

    my $deadline_hours = $q->param('deadline-hours');
    if (!defined $deadline_hours or
        $deadline_hours =~ /\D/ or
        $deadline_hours < 12 or
        $deadline_hours > 24*14) {
        error "Invalid value for the move timer (expected between 12 hours and 2 weeks)";
    }

    my %rating = ();
    for my $field (qw(min-rating max-rating)) {
        my $value = $q->param($field);
        if (defined $value and $value ne '') {
            if ($value =~ /\D/) {
                error "Invalid $field: expected an integer\n";
            }
            $rating{$field} = $value;
        }
    }

    my $user_metadata = fetch_user_metadata $dbh, $username;
    my $user_rating = ($user_metadata->{rating} // 0);
    if ($user_rating < ($rating{'min-rating'} // 0) or
        $user_rating > ($rating{'max-rating'} // 1e6)) {
        error "Can't create a game that you could not join (your rating is $user_rating)\n";
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

    my @options = $q->param('game-options');
    my $map_variant = $q->param('map-variant') || undef;

    eval {
        my $write_id = create_game $dbh, $gameid, $username, [@players], $player_count, $map_variant, @options;

        my $description = $q->param('description');
        if ($description) {
            $dbh->do("update game set description=? where id=?",
                     {},
                     $description,
                     $gameid);
        }

        $dbh->do("insert into game_options (game, description, minimum_rating, maximum_rating, deadline_hours) values (?, ?, ?, ?, ?)",
                 {},
                 $gameid,
                 $description,
                 $rating{'min-rating'},
                 $rating{'max-rating'},
                 $deadline_hours);
        
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

