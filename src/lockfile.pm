package lockfile;

use strict;
use warnings;
use Fatal qw(open);
use Fcntl qw(:flock);

sub get {
    my $lockfile = shift;
    open my $fh, ">>", $lockfile;
    $fh;
}

sub lock {
    my $fh = shift;
    flock $fh, LOCK_EX;
}

sub unlock {
    my $fh = shift;
    flock $fh, LOCK_UN;
}

sub finish {
    my $fh = shift;
    close $fh;
}

1;

