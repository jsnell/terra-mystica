#!/usr/bin/perl -w

use POSIX qw(chdir);
use CGI qw(:cgi);
use Digest::SHA1  qw(sha1_hex);
use Fatal qw(chdir open);
use File::Basename qw(dirname);
use File::Slurp;
use JSON;

chdir dirname $0;

use tracker;
use exec_timer;

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "Access-Control-Allow-Origin: *\r\n";

my $q = CGI->new;
my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9]}{}g;
my $tag = $q->param('tag');
my $max_row = $q->param('max-row');
my $preview = $q->param('preview');
my $preview_faction = $q->param('preview-faction');

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

if (-f "../../data/read/$id") {
    print "\r\n";
    my @rows = read_file("../../data/read/$id");
    my $hash = sha1_hex(join "\n", @rows);

    if ($tag and $tag eq $hash) {
        print_json { cache_valid => 1 };
        return;
    }

    if (defined $preview) {
        push @rows, (map { "$preview_faction: $_" } split /\n/, $preview);
    }

    my $res = terra_mystica::evaluate_game { rows => \@rows, max_row => $max_row };
    print_json {
        cache_valid => 0,
        action_required => $res->{action_required},
        finished => $res->{finished},
        error => $res->{error},
        tag => $hash,
    };
} else {
    print "Status: 404 Not Found\r\n";
    print "\r\n";

    my $res = { cache_valid => 0, error => [ "Unknown game: $id" ] };
    print_json $res;
}
