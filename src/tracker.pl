#!/usr/bin/perl -wl

use strict;
use JSON;

my @factions;
my %factions;
my @cults = qw(EARTH FIRE WATER WIND);

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
my @map = qw(brown gray green blue yellow red brown black red green blue red black E
             yellow x x brown black x x yellow black x x yellow E
             x x black x gray x green x green x gray x x E
             green blue yellow x x red blue x red x red brown E
             black brown red blue black brown gray yellow x x green black blue E
             gray green x x yellow green x x x brown gray brown E
             x x x gray x red x green x yellow black blue yellow E
             yellow blue brown x x x blue black x gray brown gray E
             red black gray blue red green yellow brown gray x blue green red E); 

{
    my $ri = 0;
    for my $row ('A'..'I') {
        my $col = 1;
        for my $ci (0..13) {
            my $color = shift @map;
            last if $color eq 'E';
            if ($color ne 'x') {
                $map{"$row$col"}{color} = $color;
                $map{"$row$col"}{row} = $ri;
                $map{"$row$col"}{col} = $ci;
                $col++;
            }
        }
        $ri++;
    }
}

sub setup {
    my $faction = shift;

    die "Unknown faction: $faction\n" if !$setups{$faction};

    $factions{$faction} = $setups{$faction};    
    $factions{$faction}{P} ||= 0;
    $factions{$faction}{P3} = 0;

    for (@cults) {
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
        die "Need faction for command $command\n" if !$faction;
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
        die "Need faction for command $command\n" if !$faction;
        $type = uc $1;
        my $where = uc $2;
        my $oldtype = $map{$where}{building};

        if ($oldtype) {
            $factions{$faction}{$oldtype}++;
        }

        $map{$where}{building} = $type;

        $factions{$faction}{$type}--;
    } elsif ($command =~ /^burn (\d+)$/) {
        die "Need faction for command $command\n" if !$faction;
        $factions{$faction}{P2} -= 2*$1;
        $factions{$faction}{P3} += $1;
        $type = 'P2';
    } elsif ($command =~ /^leech (\d+)$/) {
        die "Need faction for command $command\n" if !$faction;
        my $pw = $1;
        my $vp = $pw - 1;

        command $faction, "+${pw}PW";
        command $faction, "-${vp}VP";
    } elsif ($command =~ /^(\w+):(\w+)$/) {
        my $where = uc $1;
        my $color = lc $2;
        $map{$where}{color} = $color;
    } elsif ($command =~ /^block (\w+)$/) {
        my $where = uc $1;
        $map{$where}{blocked} = 1;
    } elsif ($command =~ /^clear$/) {
        $map{$_}{blocked} = 0 for keys %map;
    } elsif ($command =~ /^setup (\w+)$/) {
        setup $1;
    } elsif ($command =~ /delete (\w+)$/) {
        delete $pool{uc $1};
    } else {
        die "Could not parse command '$command'.\n";
    }

    if ($type and $faction) {
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

    if ($factions{$prefix} or $prefix eq '') {
        for my $command (@commands) {
            command $prefix, $command;
        }
    } else {
        die "Unknown prefix: '$prefix' (expected one of ".
            (join ", ", keys %factions).
            ")\n";
    }
}

sub print_pretty {
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

    for my $cult (@cults) {
        printf "%-8s", "$cult:";
        for (1..4) {
            my $key = "$cult$_";
            printf "%s / ", ($map{"$key"}{building} or ($_ == 1 ? 3 : 2));
        }
        print "";
    }
}

sub print_json {
    my $out = encode_json {
        map => \%map,
        factions => \%factions,
        pool => \%pool,
    };

    print $out;
}

while (<>) {
    handle_row $_;
}

# print_pretty;
print_json;
