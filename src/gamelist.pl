#!/usr/bin/perl -w

use POSIX qw(chdir);
use File::Basename qw(dirname);
use JSON;

sub split_nums {
    local $_ = shift;
    /(\d+|\D+)/g;
}

sub natural_cmp {
    my @a = split_nums shift;
    my @b = split_nums shift;

    while (@a and @b) {
        my $a = shift @a;
        my $b = shift @b;
        next if $a eq $b;

        if ($a =~ /\d/ and $b =~ /\d/) {
            return $a <=> $b;
        } else {
            return $a cmp $b;
        }
    }

    return @a <=> @b;
}

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";

chdir dirname $0;
my @ids = glob "../../data/read/*";
s{.*/}{} for @ids;

print encode_json [ map {
                      { id => $_ }   
                    } sort {
                        natural_cmp $a, $b;
                    } @ids ];


