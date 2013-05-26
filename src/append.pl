#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Crypt::CBC;
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

if ($q->request_method eq "OPTIONS") {
    print "Access-Control-Allow-Origin: *\r\n";
    print "Access-Control-Allow-Headers: X-Prototype-Version, X-Requested-With\r\n";
    print "\r\n";
    exit 0;
}

my $id = $q->param('game');
$id =~ s{.*/}{};
$id =~ s{[^A-Za-z0-9_]}{}g;

my $faction_name = $q->param('preview-faction');
my $faction_key = $q->param('faction-key');
my $new_content = "";

my $preview = $q->param('preview');
my $append = '';

if ($faction_name =~ /^player/) {
    $preview =~ /(setup \w+)/i;
    $append = "$1\n";
} else {
    $append = join "\n", (map { "$faction_name: $_" } grep { /\S/ } split /\n/, $preview);
}

my $dir = "../../data/write/";
my $lockfile = lockfile::get "$dir/lock";
chdir $dir;

sub verify_key {
    my $secret = read_file("../secret");
    my $iv = read_file("../iv");

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);
    $id .= "_$game_secret";
    die "Invalid faction key\n" if $id =~ /[^a-zA-z0-9_]/ or !(-f $id);

    $new_content = read_file("$id");
    chomp $new_content;
    $new_content .= "\n";

    chomp $append;
    $append .= "\n";

    $new_content .= $append;
}

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "Access-Control-Allow-Origin: *\r\n";
print "Access-Control-Expose-Headers: X-JSON\r\n";
print "\r\n";

lockfile::lock $lockfile;

eval {
    verify_key;
}; if ($@) {
    print encode_json {
        error => [ $@ ],
    };
    exit;
};

my $res = terra_mystica::evaluate_game {
    rows => [ split /\n/, $new_content ],
    delete_email => 0
};

if (!@{$res->{error}}) {
    eval {
        save $id, $new_content;
    }; if ($@) {
        print STDERR "error: $@\n";
        $res->{error} = [ $@ ]
    }
};

lockfile::unlock $lockfile;

# Ignore DB errors during metadata refresh.
if (!@{$res->{error}}) {
    eval {
        my ($read_id) = $id =~ /(.*?)_/g;
        index_game $read_id, $id, $res;
    }; if ($@) {
        print STDERR $@;
    }
}

my @email = ();

if ($terra_mystica::email) {
    push @email, $terra_mystica::email;
}

for my $faction (values %{$res->{factions}}) {
    if ($faction->{name} ne $faction_name and $faction->{email}) {
        push @email, $faction->{email}
    }
}

for (@{$res->{players}}) {
    if ($_->{email}) {
        push @email, $_->{email}
    }
}

my $out = encode_json {
    error => $res->{error},
    email => (join ",", @email),
    action_required => $res->{action_required},
    round => $res->{round},
    turn => $res->{turn},
};
print $out;
