#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Digest::SHA1  qw(sha1_hex);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

chdir dirname $0;

use exec_timer;
use indexgame;
use rlimit;
use save;
use tracker;
use lockfile;

my $q = CGI->new;

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9_]}{}g;

my $orig_hash = $q->param('orig-hash');
my $new_content = $q->param('content');

my $dir = "../../data/write/";
my $lockfile = lockfile::get "$dir/lock";

sub verify_and_save {
    chdir $dir;

    my $orig_content = read_file $id;
    if (sha1_hex($orig_content) ne $orig_hash) {
        print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
        die "Someone else made changes to the game. Please reload\n";
    }

    save $id, $new_content;
}

lockfile::lock $lockfile;

my $res = terra_mystica::evaluate_game {
    rows => [ split /\n/, $new_content ],
    delete_email => 0
};

if (!@{$res->{error}}) {
    eval {
        verify_and_save;
    }; if ($@) {
        print STDERR "error: $@\n";
        $res->{error} = [ $@ ]
    }
};

lockfile::unlock $lockfile;

if (!@{$res->{error}}) {
    # Ignore DB errors during metadata refresh.
    eval {
        my ($read_id) = $id =~ /(.*?)_/g;
        index_game $read_id, $id, $res;
    }; if ($@) {
        print STDERR $@;
    }
}

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
