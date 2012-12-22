#!/usr/bin/perl -wl

use strict;

my @factions;
my %factions;

my %setups = (
    alchemists => { C => 15, W => 3, P1 => 5, P2 => 7,
                    WATER => 1, FIRE => 1 },
    auren => { C => 15, W => 3, P1 => 5, P2 => 7,
               WATER => 1, WIND => 1 },
    swarmlings => { C => 20, W => 8, P1 => 3, P2 => 9,
                    FIRE => 1, EARTH => 1,
                    WATER => 1, WIND => 1 },
    nomads => { C => 15, W => 2, P1 => 5, P2 => 7,
                FIRE => 1, EARTH => 1 },
    engineers => { C => 10, W => 2, P1 => 3, P2 => 9 }
);

my %pool = (
    # Resources
    C => 1000,
    W => 1000,
    P => 1000,
    VP => 1000,

    # Power
    P1 => 10000,
    P2 => 10000,
    P3 => 10000,

    # Cult tracks
    EARTH => 100,
    FIRE => 100,
    WATER => 100,
    WIND => 100,
    );

$pool{"BON$_"}++ for 1..9;
$pool{"FAV$_"}++ for 1..4;
$pool{"FAV$_"} += 3 for 5..12;

my %map = ();

sub setup {
    my $faction = shift;

    die "Unknown faction: $faction\n" if !$setups{$faction};

    $factions{$faction} = $setups{$faction};    
    $factions{$faction}{P} ||= 0;
    $factions{$faction}{P3} = 0;

    for (qw(EARTH FIRE WATER WIND)) {
        $factions{$faction}{$_} ||= 0;
    }

    $factions{$faction}{D} = 8;
    $factions{$faction}{TP} = 4;
    $factions{$faction}{SH} = 1;
    $factions{$faction}{TE} = 3;
    $factions{$faction}{SA} = 1;
    $factions{$faction}{VP} = 20;

    push @factions, $faction;
}

sub command;

sub command {
    my ($faction, $command) = @_;
    my $type;

    if ($command =~ /^([+-])(\d*)(\w+)$/) {
        my ($sign, $count) = (($1 eq '+' ? 1 : -1),
                              ($2 eq '' ? 1 : $2));
        $type = uc $3;

        if ($type eq 'PW') {
            for (1..$count) {
                if ($sign > 0) {
                    if ($factions{$faction}{P1}) {
                        $factions{$faction}{P1}--;
                        $factions{$faction}{P2}++;
                        $type = 'P1';
                    } elsif ($factions{$faction}{P2}) {
                        $factions{$faction}{P2}--;
                        $factions{$faction}{P3}++;
                        $type = 'P2';
                    }
                } else {
                    $factions{$faction}{P1}++;
                    $factions{$faction}{P3}--;
                    $type = 'P3';
                }
            }
        } else {
            $pool{$type} -= $sign * $count;
            $factions{$faction}{$type} += $sign * $count;

            if ($pool{$type} < 0) {
                die "Not enough '$type' in pool after command '$command'\n";
            }
        }
    } elsif ($command =~ /^(\w+)->(\w+)$/) {
        $type = uc $1;
        my $target = uc $2;
        my $oldtype = $map{$target}{building};

        if ($oldtype) {
            $factions{$faction}{$oldtype}++;
        }

        $map{$target}{building} = $type;

        $factions{$faction}{$type}--;
    } elsif ($command =~ /^burn (\d+)/) {
        $factions{$faction}{P2} -= 2*$1;
        $factions{$faction}{P3} += $1;
        $type = 'P2';
    } elsif ($command =~ /^leech (\d+)/) {
        my $pw = $1;
        my $vp = $pw - 1;

        command $faction, "+${pw}PW";
        command $faction, "-${vp}VP";
    } else {
        die "Could not parse command '$command'.\n";
    }

    if ($type) {
        if ($factions{$faction}{$type} < 0) {
            die "Not enough '$type' in $faction after command '$command'\n";
        }
    }
}

sub handle_row {
    local $_ = shift;

    # Comment
    s/#.*//;
    s/\s+/ /g;

    $_ = lc;

    my $prefix = '';

    if (s/^(.*?)://) {
        $prefix = $1;
    }

    my @commands = split /[.]/, $_;

    for (@commands) {
        s/^\s+//;
        s/\s+$//;
        s/(\W)\s(\w)/$1$2/g;
        s/(\w)\s(\W)/$1$2/g;
    }

    @commands = grep { /\S/ } @commands;

    return if !@commands;

    if ($prefix eq 'setup') {
        setup $_ for @commands;
    } elsif ($prefix eq 'delete') {
        delete $pool{$_} for @commands;
    } elsif ($factions{$prefix}) {
        for my $command (@commands) {
            command $prefix, $command;
        }
    } else {
        die "Unknown prefix: '$prefix' (expected one of ".
            (join ", ", qw(setup delete), keys %factions).
            ")\n";
    }
}

while (<>) {
    handle_row $_;
}

for (@factions) {
    my %f = %{$factions{$_}};

    print ucfirst $_, ":";
    print "  VP: $f{VP}";
    print "  Resources: $f{C}c / $f{W}w / $f{P}p, $f{P1}/$f{P2}/$f{P3} power";
    print "  Buildings: $f{D} D, $f{TP} TP, $f{TE} TE, $f{SH} SH, $f{SA} SA";
    print "  Cults: $f{FIRE} / $f{WATER} / $f{EARTH} / $f{WIND}";

    for (1..9) {
        if ($f{"BON$_"}) {
            print "  Bonus: $_";
        }
    }

    for (1..12) {
        if ($f{"FAV$_"}) {
            print "  Favor: $_";
        }
    }
}

for my $cult (qw(EARTH FIRE WATER WIND)) {
    printf "%-8s", "$cult:";
    for (1..4) {
        my $key = "$cult$_";
        printf "%s / ", ($map{"$key"}{building} or ($_ == 1 ? 3 : 2));
    }
    print "";
}
