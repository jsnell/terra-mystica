package terra_mystica;

use strict;

use vars qw(@score_tiles);
our @score_tiles = ();

use cults;
use tiles;

sub adjust_resource;
sub command;
sub compute_network_size;

sub current_score_tile {
    if ($round > 0) {
        return $tiles{$score_tiles[$round - 1]};
    }
}

sub maybe_score_current_score_tile {
    my ($faction, $type) = @_;

    my $scoring = current_score_tile;
    if ($scoring) {
        my $gain = $scoring->{vp}{$type};
        if ($gain) {
            adjust_resource $faction, 'VP', $gain, $scoring->{vp_display};
        }
    }
}

sub maybe_score_favor_tile {
    my ($faction, $type) = @_;

    for my $tile (keys %{$faction}) {
        next if !$faction->{$tile};
        if ($tile =~ /^FAV/) {
            my $scoring = $tiles{$tile}{vp};
            if ($scoring) {
                my $gain = $scoring->{$type};
                if ($gain) {
                    adjust_resource $faction, 'VP', $gain, $tile;
                }
            }
        }
    }
}

sub score_with_ledger_entry {
    my ($faction_name, $vp, $type) = @_;
    handle_row_internal($faction_name, "+${vp}vp for $type");
}

sub score_type_rankings {
    my ($type, $fun, @scores) = @_;

    my @levels = sort { $a <=> $b } map { $factions{$_}{$type} // 0} keys %factions;
    my %scores = ();
    my %count = ();
    $count{$_}++ for @levels;

    $scores{pop @levels} += $_ for @scores;
        
    for my $faction_name (@factions) {
        my $level = $factions{$faction_name}{$type};
        next if !$level or !defined $scores{$level};
        my $vp = $scores{$level} / $count{$level};
        if ($vp) {
            $fun->($faction_name, $vp, $type);
        }
    }
}

sub score_final_cults {
    for my $cult (@cults) {
        push @ledger, { comment => "Scoring $cult cult" };
        score_type_rankings $cult, \&score_with_ledger_entry, 8, 4, 2;
    }
}

sub score_final_networks {
    compute_network_size $factions{$_} for @factions;
    push @ledger, { comment => "Scoring largest network" };
    score_type_rankings 'network', \&score_with_ledger_entry, 18, 12, 6;
}

sub score_final_resources_for_faction {
    my $faction_name = shift;
    my $faction = $factions{$faction_name};

    my $b = int($faction->{P2} / 2);
    if ($b) {
        command $faction_name, "burn $b";
    }

    for (1..($faction->{P3})) {
        command $faction_name, "convert 1pw to 1c";
    }

    for (1..($faction->{P})) {
        command $faction_name, "convert 1p to 1c";
    }

    for (1..($faction->{W})) {
        command $faction_name, "convert 1w to 1c";
    }

    my $rate = $faction->{exchange_rates}{C}{VP} // 3;
    my $vp = int($faction->{C} / $rate);
    my $c = $vp * $rate;
    if ($vp) {
        command $faction_name, "convert ${c}C to ${vp}VP";
    }
}

sub score_final_resources {
    push @ledger, { comment => "Converting resources to VPs" };

    for (@factions) {
        handle_row_internal($_, "score_resources");
    }
}

sub do_pass_vp {
    my ($faction, $fun) = @_;

    for (keys %{$faction}) {
        next if !$faction->{$_};

        my $pass_vp = $tiles{$_}{pass_vp};
        if ($pass_vp) {
            for my $type (keys %{$pass_vp}) {
                $fun->($pass_vp->{$type}[$faction->{buildings}{$type}{level}],
                       $_);
            }
        }
    }

    # XXX hack
    if ($faction->{name} eq 'engineers' and
        $faction->{buildings}{SH}{level}) {
        my $color = 'gray';
        for my $bridge (@bridges) {
            if ($bridge->{color} eq $color and
                $map{$bridge->{from}}{building} and
                $map{$bridge->{from}}{color} eq $color and
                $map{$bridge->{to}}{building} and
                $map{$bridge->{to}}{color} eq $color) {
                $fun->(3, 'SH');
            }
        }            
    }

}

sub faction_vps {
    my $faction = shift;
    my %projection = ();

    $projection{actual} = $faction->{VP};

    if (!$faction->{passed}) {
        do_pass_vp $faction, sub {
            $projection{$_[1]} += $_[0];
        };
    }
    
    my $score_to_projection = sub {
        my ($faction_name, $vp, $type) = @_;
        if ($faction->{name} eq $faction_name) {
            $projection{$type} += $vp;
        }
    };

    for (@factions) {
        if (!$factions{$_}{network}) {
            compute_network_size $factions{$_}
        }
    }
    score_type_rankings 'network', $score_to_projection, 18, 12, 6;

    for my $cult (@cults) {
        score_type_rankings $cult, $score_to_projection, 8, 4, 2;
    }

    my $rate = $faction->{exchange_rates}{C}{VP} // 3;
    my $coins = sum map { $faction->{$_} } qw(P3 C W P);
    $coins += int($faction->{P2} / 2);
    $projection{resources} = int($coins / $rate);

    $projection{total} = sum values %projection;

    return %projection;
};

1;

