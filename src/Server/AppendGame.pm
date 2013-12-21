use strict;

package Server::AppendGame;

use Moose;
use MooseX::Method::Signatures;
use Server::Server;

extends 'Server::Server';

use Crypt::CBC;

use DB::Connection;
use DB::EditLink;
use DB::Game;
use DB::IndexGame;
use DB::SaveGame;
use DB::Secret;
use Email::Notify;
use Server::Session;

use tracker;

method verify_key($dbh, $read_id, $faction_name, $faction_key) {
    my ($secret, $iv) = get_secret $dbh;

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);

    return "${read_id}_$game_secret";
};


method handle($q) {
    $self->no_cache();

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

    begin_game_transaction $dbh, $read_id;

    my $write_id = $self->verify_key($dbh,
                                     $read_id, $faction_name, $faction_key);

    if ($faction_name =~ /^player/) {
        $preview =~ /(setup (\w+))/i;
        $append = "$1\n";
        $faction_name = lc $2;
    } else {
        $append = join "\n", (map { "$faction_name: $_" } grep { /\S/ } split /\n/, $preview);
    }

    my ($prefix_content, $new_content) = get_game_content $dbh, $read_id, $write_id;
    chomp $new_content;
    $new_content .= "\n";

    chomp $append;
    $append .= "\n";
# Strip empty lines from new content
    $append =~ s/(\r\n)+/$1/g;
    $append =~ s/(\n)+/$1/g;

    $new_content .= $append;

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, "$prefix_content\n$new_content" ],
        faction_info => get_game_factions($dbh, $read_id),
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

    my %whitelist_old_email = map { ($_, 1) } qw(
 UnknownSchurken15
 Schurken17
 Schurken18
 UnknownSchurken16
 MorelikeFUNlough
 FunWithSteve1
 Morphus93
 Morphus85
 Morphus83
 Morphus88
 Morphus96
 Morphus82
 Morphus90
 Morphus95
 Morphus91
 Morphus80
 FunWithSteve
);

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
        } elsif ($whitelist_old_email{$read_id}) {
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

    my $had_error = scalar @{$res->{error}};

    my $out = {
        error => $res->{error},
        email => (join ",", @email),
        action_required => $res->{action_required},
        round => $res->{round},
        turn => $res->{turn},
        new_faction_key => (($orig_faction_name eq $faction_name or $had_error) ?
                            undef :
                            edit_link_for_faction $dbh, $write_id, $faction_name),
    };
    eval {
        ($out->{chat_message_count},
         $out->{chat_unread_message_count}) = get_chat_count($dbh, $read_id, $username);
    };

    $self->output_json($out);
}

1;
