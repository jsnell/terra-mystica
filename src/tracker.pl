#!/usr/bin/perl -wl

package terra_mystica;

use strict;
use JSON;
use File::Basename qw(dirname);

BEGIN {
    my $target = shift @ARGV;
    unshift @INC, "$target/cgi-bin/";
}

use tracker;

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

my @rows = <>;
my $res = evaluate_game { rows => [ @rows ] };
print_json $res;

if (scalar @{$res->{error}}) {
    print STDERR $_ for @{$res->{error}};
    exit 1;
}

