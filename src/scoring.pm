package terra_mystica;

use strict;

use vars qw(%game %map);

use Game::Constants;

sub adjust_resource;
sub command;
sub compute_network_size;
sub compute_connected_distance;

sub current_score_tile {
    if ($game{round} > 0) {
        return $tiles{$game{score_tiles}[$game{round} - 1]};
    }
}

sub maybe_score_current_score_tile {
    my ($faction, $type, $mode) = @_;

    my $scoring = current_score_tile;
    if ($scoring) {
        my $gain = $scoring->{vp}{$type};
        if ($gain and $mode eq $scoring->{vp_mode}) {
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
    my ($faction, $vp, $type) = @_;
    handle_row_internal($faction->{name}, "+${vp}vp for $type");
}

sub score_type_rankings {
    my ($type, $fun, @scores) = @_;

    my @levels = sort { $a <=> $b } map { $_->{$type} // 0} $game{acting}->factions_in_order();
    my %scores = ();
    my %count = ();
    $count{$_}++ for @levels;

    for (@scores) {
        if (@levels) {
            $scores{pop @levels} += $_ 
        }
    }

    for my $faction ($game{acting}->factions_in_order()) {
        my $level = $faction->{$type};
        next if !$level or !defined $scores{$level};
        my $vp = int($scores{$level} / $count{$level});
        if ($vp) {
            $fun->($faction, $vp, $type);
        }
    }
}

sub score_final {
    compute_network_size $_ for $game{acting}->factions_in_order();

    for my $type (sort keys %{$game{final_scoring}}) {
        my @points = @{$game{final_scoring}{$type}{points}};
        if ($type eq 'cults') {
            for my $type (@cults) {
                $game{ledger}->add_comment("Scoring $type cult");
                score_type_rankings $type, \&score_with_ledger_entry, @points;
            }
        } else {
            $game{ledger}->add_comment("Scoring $type");
            score_type_rankings $type, \&score_with_ledger_entry, @points;
        }
    }
}

sub score_final_resources_for_faction {
    my $faction = shift;
    my $faction_name = $faction->{name};

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
    $game{ledger}->add_comment("Converting resources to VPs");

    for ($game{acting}->factions_in_order()) {
        handle_row_internal($_->{name}, "score_resources");
    }
}

sub do_pass_vp {
    my ($faction, $fun) = @_;

    for (keys %{$faction}) {
        next if !$faction->{$_};
        my $tile = $tiles{$_};

        next if !$tile;

        if ($tile->{pass_vp}) {
            my $pass_vp = $tiles{$_}{pass_vp};
            for my $type (keys %{$pass_vp}) {
                my $level = $faction->{buildings}{$type}{level} //
                    $faction->{$type}{level};
                $fun->($pass_vp->{$type}[$level], $_);
            }
        }
    }

    for my $building (values %{$faction->{buildings}}) {
        my $pass_vps = $building->{pass_vp};
        next if !defined $pass_vps;
        my $pass_vp = $pass_vps->[$building->{level}];

        for my $type (keys %{$pass_vp}) {
            my $level = $faction->{buildings}{$type}{level} //
                $faction->{$type}{level};
            $fun->($pass_vp->{$type}[$level], $_);
        }
    }

    # XXX hack
    if ($faction->{name} eq 'engineers' and
        $faction->{buildings}{SH}{level}) {
        my $color = 'gray';
        for my $bridge (@{$game{bridges}}) {
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
        my ($score_faction, $vp, $type) = @_;
        if ($faction == $score_faction) {
            $projection{$type} += $vp;
        }
    };

    for my $faction ($game{acting}->factions_in_order()) {
        if (!$faction->{network}) {
            compute_network_size $faction
        }
    }
    for my $type (keys %{$game{final_scoring}}) {
        my @points = @{$game{final_scoring}{$type}{points}};
        if ($type eq 'cults') {
            for my $type (@cults) {
                score_type_rankings $type, $score_to_projection, 8, 4, 2;
            }
        } else {
            score_type_rankings $type, $score_to_projection, 18, 12, 6;
            $projection{$type} ||= 0;
            if ($type ne 'network') {
                $projection{$type} .= " [$faction->{$type}]";
            }
        }
    }

    my $rate = $faction->{exchange_rates}{C}{VP} // 3;
    my $coins = sum map { $faction->{$_} } qw(P3 C W P);
    $coins += int($faction->{P2} / 2);
    $projection{resources} = int($coins / $rate);
    $projection{total} = sum values %projection;

    {
        my $total = sum map {
            $faction->{buildings}{$_}{level}
        } qw(D TP TE SH SA);
        $projection{network} ||= 0;
        $projection{network} .=  " [".$faction->{network}."/$total]";
    }

    return %projection;
};

1;

