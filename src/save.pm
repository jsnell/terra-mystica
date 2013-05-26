#!/usr/bin/perl -w

use strict;

use File::Temp qw(tempfile);

sub save {
    my ($id, $new_content) = @_;

    my ($fh, $filename) = tempfile("tmpfileXXXXXXX",
                                   DIR=>".");
    print $fh $new_content;
    close $fh;
    chmod 0444, $filename;
    rename $filename, "$id";

    system "git commit -m 'change $id' $id > /dev/null";
}

1;
