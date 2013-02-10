#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Digest::SHA1  qw(sha1_hex);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use File::Temp qw(tempfile);
use JSON;

chdir dirname $0;

BEGIN { push @INC, "../../git/src"; }

use tracker;

my $q = CGI->new;

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9_]}{}g;

my $orig_hash = $q->param('orig-hash');
my $new_content = $q->param('content');

my $dir = "../../data/write/";

sub save {
    chdir $dir;

    my $orig_content = read_file $id;
    if (sha1_hex($orig_content) ne $orig_hash) {
        print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
        die "Someone else made changes to the game. Please reload\n";
    }

    my ($fh, $filename) = tempfile("tmpfileXXXXXXX",
                                   DIR=>".");
    print $fh $new_content;
    close $fh;
    chmod 0444, $filename;
    rename "$id", "$id.bak";
    rename $filename, "$id";

    system "git commit -m 'change $id' $id > /dev/null";
}

my $res = terra_mystica::evaluate_game { rows => [ split /\n/, $new_content ] };

if (!@{$res->{error}}) {
    eval {
        save;
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
    action_required => $res->{action_required},
    factions => $res->{factions},
};
print $out;
