package Util::NaturalCmp;
use Exporter::Easy (EXPORT => [ 'natural_cmp' ]);

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

1;
