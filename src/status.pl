#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use JSON;
use File::Basename qw(dirname);

BEGIN { push @INC, dirname $0; }

use tracker;

sub print_status {
    printf("%25s % 5s % 5s % 5s % 8s % 5s\n",
           qw(Faction W C P PW VP));
    print '-' x 65;
    for my $faction_name (@factions) {
        my $faction = $factions{$faction_name};
        printf("%25s % 5d % 5d % 5d % 8s % 5d\n",
               $faction->{display},
               $faction->{W}, 
               $faction->{C}, 
               $faction->{P}, 
               (sprintf "%d/%d/%d", $faction->{P1}, $faction->{P2}, $faction->{P3}),
               $faction->{VP});
    }
    print '-' x 65;
}

my $res = evaluate_game { rows => [ <> ] };
print_status $res;

if ($res->{error}) {
    print STDERR $_ for @{$res->{error}};
    exit 1;
}

