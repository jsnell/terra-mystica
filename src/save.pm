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

    eval {
        my ($read_id) = $id =~ /(.*?)_/g;
        my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                               { AutoCommit => 0, RaiseError => 1});
        $dbh->do("update game set commands=? where id=?", {},
                 $new_content, $read_id);
        $dbh->commit();
        $dbh->disconnect();
    }; if ($@) {
        print "db error: $@";
    }
}

1;
