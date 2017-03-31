#!perl

package DB::AddGames;

use Exporter::Easy (
    EXPORT => [qw(validate make_games)]
    );

use strict;
no indirect;

use DBI;
use JSON;

use DB::Connection;
use DB::Game;
use DB::SaveGame;
use DB::UserValidate;
use Email::Notify;

sub validate {
    my ($dbh, $desc) = @_;
    my $games = $desc->{games};
    my $options = $desc->{options};

    my %order = ();
    my %count = ();

    for my $game_desc (@{$games}) {
        my $id = $game_desc->{name};
        my @players = @{$game_desc->{players}};
        for (my $i = 0; $i < @players; ++$i) {
            my $player = $players[$i];
            if ($order{$player}{$i}) {
                die "$player on position $i in multiple games ($order{$player}{$i}, $id)\n"
            }
            $order{$player}{$i} = $id;
            $count{$player}++;
            die "Someone trying to add a test account\n" if $player eq 'test' or $player eq 'test2' or $player eq 'TestCapital';
        }
    }

    for my $player (keys %count) {
        if ($count{$player} != $desc->{'games-per-player'}) {
            die "$player playing in $count{$player} matches (wanted $desc->{'games-per-player'})\n"
        }
        check_username_is_registered $dbh, $player;
    }
    
    my $chess_clock_settings = scalar grep { defined $_ } map { $desc->{$_} } qw(chess-clock-hours-initial chess-clock-hours-per-round chess-clock-grace-period);
    if (($chess_clock_settings != 0 and $chess_clock_settings != 3) or
        ($chess_clock_settings == 0 and !defined $desc->{'deadline-hours'}) or
        ($chess_clock_settings == 3 and defined $desc->{'deadline-hours'})) {
        die "Inconsistent chess clock / deadline settings\n";
    }

    check_username_is_registered $dbh, $desc->{admin};

    my %valid_options = map { ($_, 1) } qw(
            errata-cultist-power
            mini-expansion-1
            shipping-bonus
            temple-scoring-tile
            email-notify
            maintain-player-order
            strict-leech
            strict-chaosmagician-sh
            strict-darkling-sh
            variable-turn-order);
    for my $opt (@{$options}) {
        if (!$valid_options{$opt}) {
            die "Unknown option $opt\n";
        }
    }
}

sub make_games {
    my ($dbh, $desc) = @_;
    my $games = $desc->{games};
    my $options = $desc->{options};
    my $player_count = undef;
    my $admin = $desc->{admin};

    my @to_create = ();

    for my $game_desc (@{$games}) {
        my $id = $game_desc->{name};
        if (game_exists $dbh, $id) {
            print "Game $id already exists, skipping\n";
        } else {
            push @to_create, $game_desc;
        }
    }

    my $map_variant = undef;

    for my $game_desc (@to_create) {
        $dbh->do("begin");
        my $id = $game_desc->{name};
        my @players = map {
            my $player = $_;
            my ($username, $email) =
                check_username_is_registered $dbh, $player;
            { email => $email, username => $username }
        } @{$game_desc->{players}};

        print "Creating $id with @{$game_desc->{players}}\n";

        create_game($dbh,
                    $id,
                    $admin,
                    [ @players ],
                    $player_count,
                    $map_variant,
                    @{$options});

        

        $dbh->do("update game set description=?, current_chess_clock_hours=? where id=?",
                 {},
                 $game_desc->{'description'},
                 $desc->{'chess-clock-hours-initial'},
                 $id);

        $dbh->do("insert into game_options (game, description, minimum_rating, maximum_rating, deadline_hours, chess_clock_hours_initial, chess_clock_hours_per_round, chess_clock_grace_period) values (?, ?, ?, ?, ?, ?, ?, ?)",
                 {},
                 $id,
                 $game_desc->{'description'},
                 $desc->{'minimum-rating'},
                 $desc->{'maximum-rating'},
                 $desc->{'deadline-hours'},
                 $desc->{'chess-clock-hours-initial'},
                 $desc->{'chess-clock-hours-per-round'},
                 $desc->{'chess-clock-grace-period'});

        notify_game_started $dbh, {
            name => $id,
            options => { map { ($_ => 1) } @{$options} },
            players => [ values %{get_game_factions($dbh, $id)} ],
        };

        $dbh->do("commit");

        sleep 1;
    }
}

1;
