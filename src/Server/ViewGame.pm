use strict;
no indirect;

package Server::ViewGame;

use Moose;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection qw(get_db_connection);
use DB::Game;
use Server::Security;
use Server::Session;
use Util::CryptUtil;
use Util::NaturalCmp;
use Util::ServerUtil;
use tracker;

method handle($q) {
    $self->no_cache();

    my $id = $q->param_or_die('game');
    $id =~ s{.*/}{};
    $id =~ s{[^A-Za-z0-9_]}{}g;
    my $max_row = $q->param('max-row');
    my $preview = $q->param('preview');
    my $preview_faction = $q->param('preview-faction');

    my $dbh = get_db_connection;
    my $username = username_from_session_token(
        $dbh,
        $q->cookie('session-token') // '');

    if (!game_exists($dbh, $id)) {
        $self->status(404);
        $self->output_json({ error => [ "Unknown game: $id" ] });
        log_with_request $q, "Unknown game: $id";
        return;
    }

    my @rows = get_game_commands $dbh, $id;

    if (defined $preview) {
        push @rows, 'start-preview';
        if ($preview_faction =~ /^player/) {
            if ($preview =~ /^(\s*resign\s*)$/) {
                push @rows, "drop-faction $preview_faction";
            } elsif ($preview =~ s/(setup (\w+))//i) {
                push @rows, "$1\n";
                $preview_faction = lc $2;
                push @rows, (map { "$preview_faction: $_" } grep { /\S/ } split /\n/, $preview);
            }
        } else {
            my $plan_faction = $preview_faction;
            # For each nesting level: 0 if we're in a true branch,
            # 1 if we're in a false branch, 2 if we've already executed
            # the true branch and are in an else or elsif that should
            # not be executed.
            my @if_state = ();
            # Start from -1 to account for the hidden start-planning
            # inserted by JS before posting the request.
            my $row = -1;
            eval {
                for (split /\n\r*/, $preview) {
                    ++$row;
                    s/\s*$//;
                    if (/^!if\s*(true|false)\s*$/) {                    
                        push @if_state, ($1 eq 'false' ? 1 : 0);
                    } elsif (/^!else\s*$/) {
                        if (!@if_state) {
                            die "!else with no matching !if\n";
                        }
                        if ($if_state[-1] == 0) {
                            $if_state[-1] = 2;
                        } elsif ($if_state[-1] == 1) { 
                            $if_state[-1] = 0;
                        }
                    } elsif (/^!elsif\s*(true|false)\s*$/) {
                        if (!@if_state) {
                            die "!elsif with no matching !if\n";
                        }
                        if ($if_state[-1] == 0) {
                            # Going from a true branch to an else
                            $if_state[-1] = 2;
                        } elsif ($if_state[-1] == 2) {
                            # We've already seen the true branch in
                            # the past.
                        } else {
                            # All previously seen conditionals were false.
                            # We might execute this branch.
                            if ($1 eq 'true')  {
                                $if_state[-1] = 0;
                            }
                        }
                    } elsif (/^!endif$/) {
                        if (!@if_state < 0) {
                            die "!endif with no matching !if\n";
                        }
                        pop @if_state;
                    } elsif (/^!plan (\w+)$/i) {
                        $plan_faction = $1;
                        push @rows, "$plan_faction: start_planning";
                    } elsif (/^!/) {
                        die "unknown planning command '$_'\n";
                    } elsif (grep { $_ } @if_state) {
                        # Inside at least one false branch
                    } else {
                        push @rows, "$plan_faction: $_";
                    }
                }
                if (@if_state) {
                    die join '', "At end of input, but still have an unclosed !if";
                }
            }; if ($@) {
                $self->status(400);
                $self->output_json({
                    error => [ "Error on line $row: $@" ]});
                return;
            }
        }
    }

    my $players = get_game_players($dbh, $id);
    my $metadata = get_game_metadata($dbh, $id);

    my $res = terra_mystica::evaluate_game {
        rows => \@rows,
        faction_info => get_game_factions($dbh, $id),
        players => $players,
        metadata => $metadata,
        max_row => $max_row
    };
    eval {
        ($res->{chat_message_count},
         $res->{chat_unread_message_count}) = get_chat_count($dbh, $id, $username);
    };
    $res->{metadata} = get_game_metadata $dbh, $id;

    if ($q->param('template')) {
        if (!$username) {
            die "Not logged in\n";
        }

        if ($username ne $res->{metadata}{admin_user}) {
            die "Game is administrated by another player\n";
        }

        $res->{template_next_game_id} = find_next_game_id($dbh, $id, $username);
    }

    $self->output_json($res);
};

sub find_next_game_id {
    my ($dbh, $id, $username) = @_;
    my $base_id = $id;
    $base_id =~ s/\d+$//;

    if (length $base_id < 4) {
        $base_id = $username;
    }

    $base_id =~ s/[^A-Za-z0-9]//g;

    my @games = ();

    for (@{$dbh->selectall_arrayref(
               "select id from game where id like ?",
               { Slice => {} },
               "$base_id%")}) {
        my $game_id = $_->{id};
        if ($game_id !~ /^$base_id[^0-9]/) {
            push @games, $game_id;
        }
    }

    if (@games == 1) {
        return "${base_id}02";
    }

    @games = sort { natural_cmp $a, $b } @games;
    my $last = $games[-1];
    $last =~ s/^$base_id//;
    my $next = sprintf "%02d", $last + 1;

    return "${base_id}$next";
}

1;
