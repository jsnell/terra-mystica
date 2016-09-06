#!/usr/bin/perl -wl

package Analyze::EloVpPredictor;
use Exporter::Easy (EXPORT => ['faction_vp_error_by_map']);

use strict;

use DBI;
use File::Slurp;
use JSON;
use List::Util qw(sum);
use Statistics::Descriptive;

use Analyze::RatingData;

sub faction_vp_error_by_map {
    my ($dbh, $map) = @_;

    my $players = $dbh->selectall_hashref("select player, rating as score from player_ratings",
                                          'player');

    my %stats = ();

    my $results = read_rating_data $dbh, sub {
        my $res = shift;
        return $res->{base_map} &&
            $res->{base_map} eq $map;
    },  {include_unranked => 1 };

    my %diffs = ();
    my %counts = ();
    for my $record (@{$results->{results}}) {
        my $a_vp = $record->{a}{vp};
        my $b_vp = $record->{b}{vp};

        my $a_elo = $players->{$record->{a}{username}}{score};
        my $b_elo = $players->{$record->{b}{username}}{score};

        my $a_faction = $record->{a}{faction};
        my $b_faction = $record->{b}{faction};

        next if $record->{a}{dropped} or $record->{b}{dropped};
        next if !$a_elo or !$b_elo;

        my $d_vp = $a_vp - $b_vp;
        my $d_elo = $a_elo - $b_elo;
        my $e_vp = $d_elo / 10;

        push @{$diffs{$a_faction}}, $d_vp - $e_vp;
        push @{$diffs{$b_faction}}, -($d_vp - $e_vp);

        for my $f ($a_faction, $b_faction) {
            $counts{$f}{$record->{id}}++;
        }
    }

    my %stat = map {
        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@{$diffs{$_}});
        my $count = scalar keys %{$counts{$_}};
        ($_, {
            count => $count,
            mean => $stat->mean(),
            sterr => $stat->standard_deviation() / sqrt($count),
         });
    } keys %diffs;

    \%stat;
}

1;
