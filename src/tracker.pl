#!/usr/bin/perl -wl

package terra_mystica;

use List::Util qw(max);
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
# @rows = @rows[0..(min $ENV{MAX_ROW}, scalar(@rows)-1)];

my $res = evaluate_game { rows => [ @rows ] };
print_json $res;

if (scalar @{$res->{error}}) {
    print STDERR $_ for @{$res->{error}};
    exit 1;
}

