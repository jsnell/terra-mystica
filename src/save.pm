#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Digest::SHA1  qw(sha1_hex);
use Fatal qw(chdir open rename);
use File::Slurp;
use File::Temp qw(tempfile);
use JSON;
use tracker;

sub verify_checksum {
    my ($id, $dir, $orig_hash) = @_;

    my $orig_content = read_file "$dir/$id";
    if (sha1_hex($orig_content) ne $orig_hash) {
        print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
        die "Someone else made changes to the game. Please reload\n";
    }
}

sub save {
    my ($id, $dir, $new_content) = @_;

    my ($fh, $filename) = tempfile("tmpfileXXXXXXX",
                                   DIR => $dir);
    print $fh $new_content;
    close $fh;
    chmod 0444, $filename;
    rename "$dir/$id", "$dir/$id.bak";
    rename $filename, "$dir/$id";

    system "cd '$dir' && git commit -m 'change $id' $id > /dev/null";
}

sub serve {
    my $datadir = shift;
    my $q = CGI->new;

    my $id = $q->param('game');
    $id =~ s{.*/}{};
    $id =~ s{[^A-Za-z0-9_]}{}g;

    my $orig_hash = $q->param('orig-hash');
    my $new_content = $q->param('content');

    my $writedir = "$datadir/write/";

    my $res = terra_mystica::evaluate_game split /\n/, $new_content;

    if (!@{$res->{error}}) {
        eval {
            verify_checksum $id, $writedir, $orig_hash;
            save $id, $writedir, $new_content;
        }; if ($@) {
            print STDERR "error: $@\n";
            $res->{error} = [ $@ ]
        }
    };

    print "Content-type: text/json\r\n";
    print "Cache-Control: no-cache\r\n";
    print "\r\n";
    
    my $out = encode_json {
        error => $res->{error},
        hash => sha1_hex($new_content),
    };
    print $out;
}

1;

