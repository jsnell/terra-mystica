#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use DBI;
use Digest::SHA1  qw(sha1_hex);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

chdir dirname $0;

use exec_timer;
use game;
use rlimit;
use save;
use tracker;

my $q = CGI->new;

my $write_id = $q->param('game');
$write_id =~ s{.*/}{};
$write_id =~ s{[^A-Za-z0-9_]}{}g;
my ($read_id) = $write_id =~ /(.*?)_/g;

my $orig_hash = $q->param('orig-hash');
my $new_content = $q->param('content');

my $dir = "../../data/write/";

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1, RaiseError => 1 });

sub verify_and_save {
    my $game = shift;

    chdir $dir;

    my $orig_content = get_game_content $dbh, $read_id, $write_id;

    if (sha1_hex($orig_content) ne $orig_hash) {
        print STDERR "Concurrent modification [$orig_hash] [", sha1_hex($orig_content), "]";
        die "Someone else made changes to the game. Please reload\n";
    }

    save $dbh, $write_id, $new_content, $game;
}

begin_game_transaction $dbh, $read_id;

my $res = terra_mystica::evaluate_game {
    rows => [ split /\n/, $new_content ],
    delete_email => 0
};

if (!@{$res->{error}}) {
    eval {
        verify_and_save $res;
    }; if ($@) {
        print STDERR "error: $@\n";
        $res->{error} = [ $@ ]
    }
};

finish_game_transaction $dbh;

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
