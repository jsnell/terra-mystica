use Time::HiRes qw(time);

BEGIN {
    our $start_time = time;
}
END {
    print STDERR "$0: ", (time - $start_time), "\n";
}

1;
