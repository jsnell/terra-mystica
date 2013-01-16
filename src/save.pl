#!/usr/bin/perl -w

use File::Basename qw(dirname);
chdir dirname $0;

BEGIN {
    push @INC, ".";
    push @INC, "../git/src";
}

use save;

serve "../data/";

