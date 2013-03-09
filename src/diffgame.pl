#!/usr/bin/perl -wl

use strict;
use warnings;
use File::Basename qw(dirname);
use JSON;
use Text::Diff qw(diff);

my $dir = dirname $0;

sub pretty_res {
    my $res = qx(perl $dir/tracker.pl @_);
    my $json = decode_json $res;
    $json;
#    my $pretty = to_json($json, { pretty => 1 });
#    $pretty;
}

my ($dir1, $dir2) = (shift, shift);

sub convert_ledger {
    my $data = shift;
    return $data if !ref $data;

    # command / comment only
    return [ map { [ $_->{commands} || $_->{comment} ] } @{$data} ];        
}

for (@ARGV) {
    print "Evaluating $_";
    my $a = pretty_res $dir1, $_;
    my $b = pretty_res $dir2, $_;

    for my $key (keys %{$a}) {
        my $aa = $a->{$key};
        my $bb = $b->{$key};

        if (!ref $aa or !ref $bb) {
            next;
        }

        if ($key eq 'ledger') {
            $aa = convert_ledger $aa;
            $bb = convert_ledger $bb;
            my $aj = join "\n", map { to_json($_) } @{$aa};
            my $bj = join "\n", map { to_json($_) } @{$bb};
            if ($aj ne $bj) {
                print "Ledger diffs";
                # print diff \$aj, \$bj;
            }
        } else {
            my $aj = to_json($aa, { pretty => 1, canonical => 1 });
            my $bj = to_json($bb, { pretty => 1, canonical => 1 });
            if ($aj ne $bj) {
                print diff \$aj, \$bj;
            }
        }
    }
}
