#!/usr/bin/perl -w

use CGI qw(:cgi);
use JSON;

use db;
use create_game;
use game;
use session;
use user_validate;

my $q = CGI->new;
my $dbh = get_db_connection;

verify_csrf_cookie_or_die $q;

print "Content-Type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

sub error {
    print encode_json {
        error => [ @_ ],
    };
    exit;
};

if (!$username) {
    print encode_json {
        error => "Login required",
        link => "/login/#required",
    };
    exit;
}

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

if ($game_type eq 'private') {
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
        if ($player =~ /\@/) {
            check_email_is_registered $dbh, $player;
        } else {
            ($player) = check_username_is_registered $dbh, $player;
        }
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

    print encode_json {
        error => [],
        link => "/edit/$write_id"
    };
}; if ($@) {
    error $@;
}

finish_game_transaction $dbh;
