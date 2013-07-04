#!/usr/bin/perl -w

use strict;

use CGI qw(:cgi);
use Crypt::CBC;
use DBI;
use JSON;

use exec_timer;
use game;
use indexgame;
use rlimit;
use save;
use secret;
use tracker;

my $q = CGI->new;

if ($q->request_method eq "OPTIONS") {
    print "Access-Control-Allow-Origin: *\r\n";
    print "Access-Control-Allow-Headers: X-Prototype-Version, X-Requested-With\r\n";
    print "\r\n";
    exit 0;
}

my $read_id = $q->param('game');
$read_id =~ s{.*/}{};
$read_id =~ s{[^A-Za-z0-9_]}{}g;

my $faction_name = $q->param('preview-faction');
my $faction_key = $q->param('faction-key');

my $preview = $q->param('preview');
my $append = '';

if ($faction_name =~ /^player/) {
    $preview =~ /(setup \w+)/i;
    $append = "$1\n";
} else {
    $append = join "\n", (map { "$faction_name: $_" } grep { /\S/ } split /\n/, $preview);
}

my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                       { AutoCommit => 1, RaiseError => 1});

sub verify_key {
    my ($secret, $iv) = get_secret $dbh;

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);
    return "${read_id}_$game_secret";
}

print "Content-type: text/json\r\n";
print "Cache-Control: no-cache\r\n";
print "Access-Control-Allow-Origin: *\r\n";
print "Access-Control-Expose-Headers: X-JSON\r\n";
print "\r\n";

begin_game_transaction $dbh, $read_id;

my $write_id;
eval {
    $write_id = verify_key;
}; if ($@) {
    print encode_json {
        error => [ $@ ],
    };
    exit;
};


my $new_content = get_game_content $dbh, $read_id, $write_id;
chomp $new_content;
$new_content .= "\n";

chomp $append;
$append .= "\n";

$new_content .= $append;

my $res = terra_mystica::evaluate_game {
    rows => [ split /\n/, $new_content ],
    players => get_game_players($dbh, $read_id),
    delete_email => 0
};

if (!@{$res->{error}}) {
    eval {
        save $dbh, $write_id, $new_content, $res;
    }; if ($@) {
        print STDERR "error: $@\n";
        $res->{error} = [ $@ ]
    }
};

finish_game_transaction $dbh;

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
