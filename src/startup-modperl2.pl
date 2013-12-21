#!/usr/bin/perl

use strict;
use warnings;
use Apache2::ServerUtil;
use File::Basename qw(dirname);

BEGIN {
    eval {
        my $restart_count = Apache2::ServerUtil::restart_count();

        return if $restart_count == 0;

        my $root = dirname __FILE__;

        require lib;
        lib->import($root);

        require Plack::Handler::Apache2;

        my @psgis = ("$root/app.psgi");
        foreach my $psgi (@psgis) {
            print STDERR "preloading $psgi\n";
            Plack::Handler::Apache2->preload($psgi);
        }
    }; if ($@) {
        print STDERR "startup error: $@\n";
    }
}

1; # file must return true!
