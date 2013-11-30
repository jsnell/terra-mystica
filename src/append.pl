#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Crypt::CBC;
use JSON;

use db;
use editlink;
use exec_timer;
use game;
use indexgame;
use notify;
use rlimit;
use save;
use secret;
use session;
use tracker;

my $q = CGI->new;

my $read_id = $q->param('game');
$read_id =~ s{.*/}{};
$read_id =~ s{[^A-Za-z0-9_]}{}g;

my $faction_name = $q->param('preview-faction');
my $faction_key = $q->param('faction-key');
my $orig_faction_name = $faction_name;

my $preview = $q->param('preview');
my $append = '';

my $dbh = get_db_connection;
my $username = username_from_session_token($dbh,
                                           $q->cookie('session-token') // '');

sub verify_key {
    my ($secret, $iv) = get_secret $dbh;

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);
    return "${read_id}_$game_secret";
}

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

begin_game_transaction $dbh, $read_id;

my $write_id;
eval {
    $write_id = verify_key;
}; if ($@) {
    print encode_json {
        error => [ $@ ],
    };
    exit;
};


if ($faction_name =~ /^player/) {
    $preview =~ /(setup (\w+))/i;
    $append = "$1\n";
    $faction_name = lc $2;
} else {
    $append = join "\n", (map { "$faction_name: $_" } grep { /\S/ } split /\n/, $preview);
}


my $new_content = get_game_content $dbh, $read_id, $write_id;
chomp $new_content;
$new_content .= "\n";

chomp $append;
$append .= "\n";

$new_content .= $append;

my $res = terra_mystica::evaluate_game {
    rows => [ split /\n/, $new_content ],
    players => get_game_players($dbh, $read_id),
    delete_email => 0
};

if (!@{$res->{error}}) {
    eval {
        save $dbh, $write_id, $new_content, $res;
    }; if ($@) {
        print STDERR "error: $@\n";
        $res->{error} = [ $@ ]
    }
};

finish_game_transaction $dbh;

my @email = ();

if (!@{$res->{error}}) {
    if ($res->{options}{'email-notify'}) {
        my $factions = $dbh->selectall_arrayref(
            "select game_role.faction as name, email, player.displayname from game_role left join email on email.address = game_role.email left join player on email.player = player.username where game = ? and faction != 'admin' and email is not null",
            { Slice => {} },
            $read_id);
        for my $faction (@{$factions}) {
            my $eval_faction = $res->{factions}{$faction->{name}};
            if ($eval_faction) {
                $faction->{recent_moves} = $eval_faction->{recent_moves};
                $faction->{VP} = $eval_faction->{VP};
            }
        }
        my $game = {
            name => $read_id,
            factions => { map { ($_->{name}, $_) } @{$factions} },
            finished => $res->{finished},
            options => $res->{options},
            action_required => $res->{action_required},
        };
        notify_after_move $dbh, $write_id, $game, $faction_name, $append;
    } else {
        # Automatic notifications are off, allow for manual emailing.
        if ($terra_mystica::email) {
            push @email, $terra_mystica::email;
        }

        for my $faction (values %{$res->{factions}}) {
            if ($faction->{name} ne $faction_name and $faction->{email}) {
                push @email, $faction->{email}
            }
        }

        for (@{$res->{players}}) {
            if ($_->{email}) {
                push @email, $_->{email}
            }
        }
    }
}

my $out = encode_json {
    error => $res->{error},
    email => (join ",", @email),
    action_required => $res->{action_required},
    round => $res->{round},
    turn => $res->{turn},
    new_faction_key => ($orig_faction_name eq $faction_name ?
                        undef :
                        edit_link_for_faction $dbh, $write_id, $faction_name),
};
eval {
    ($out->{chat_message_count},
     $out->{chat_unread_message_count}) = get_chat_count($dbh, $read_id, $username);
};
print $out;
