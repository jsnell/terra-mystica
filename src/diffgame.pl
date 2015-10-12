#!/usr/bin/perl -wl

use strict;
use warnings;

use File::Basename qw(dirname);
use IPC::Open2;
use JSON;
use Text::Diff qw(diff);

BEGIN { push @INC, dirname $0 };

use DB::Connection;

my $dir = dirname $0;
my $time = 'total';
my %time = ();

my %procs = ();
sub get_proc {
    my ($target) = @_;
    if (!$procs{$target}) {
        my $pid = open2(my $reader, my $writer, "perl $dir/tracker.pl $target");
        $procs{$target} = {
            output => $reader,
            input => $writer,
            pid => $pid,
        };
    }

    return $procs{$target};
}

sub request_result {
    my ($target, $game) = @_;
    my $proc = get_proc $target;
    my $in = $proc->{input};

    print $in "$game";    
}

sub fetch_result {
    my ($target, $game) = @_;
    my $proc = get_proc $target;
    my $out = $proc->{output};
    my $res = <$out>;
    my $json = decode_json $res;
    my $cost = $json->{cost};

    if ($time eq 'total') {
        $time{$target} += $cost;
    } elsif ($time eq 'single') {
        printf "  %s: %5.3f\n", $target, $cost;
    }

    for my $faction (values %{$json->{factions}}) {
        delete $faction->{recent_moves};
        delete $faction->{leech_effect};
        delete $faction->{action};
        delete $faction->{ACTE};
        delete $faction->{exchange_rates};
        delete $faction->{ALLOW_SHAPESHIFT};
        delete $faction->{GAIN_P3_FOR_VP};
        delete $faction->{CULT_P};
        delete $faction->{disable_spade_decline};
        delete $faction->{locked_terrain};
        delete $faction->{income_taken};
    }
    delete $json->{actions};
    delete $json->{towns};
    delete $json->{score_tiles};
    delete $json->{bonus_tiles};
    delete $json->{events};
    delete $json->{pool}{CULT};
    delete $json->{pool}{UNLOCK_TERRAIN};
    delete $json->{pool}{MAX_P};
    delete $json->{pool}{ALLOW_SHAPESHIFT};
    delete $json->{pool}{GAIN_P3_FOR_VP};
    delete $json->{map}{ACTE};

    $json;
#    my $pretty = to_json($json, { pretty => 1 });
#    $pretty;
}

my ($dir1, $dir2) = (shift, shift);

sub convert_ledger {
    my $data = shift;
    return $data if !ref $data;

    # command / comment only
    return [ map { [ $_->{commands} || $_->{comment}, $_->{warning}] } @{$data} ];        
}

my $dbh = get_db_connection;

my $games = $dbh->selectall_arrayref("select id, write_id, extract(epoch from last_update) from game where id like ? order by last_update",
                                     {},
                                     shift || '%');

# my $games = $dbh->selectall_arrayref("select id, write_id, extract(epoch from last_update) from game where id like ? and 0 = (select count(*) from game_role where game.id=game_role.game and faction='riverwalkers') order by last_update",
#                                      {},
#                                      shift || '%');

my $count = 0;
my $diffcount = 0;

for (@{$games}) {
    my $id = $_->[0];
    ++$count;

    {
        local $| = 1; 
        printf "."; 
    }

    if ($count % 40 == 0) {
        print " [", $count, "/", (scalar @{$games}), " -> $diffcount diffs]\n";
        if ($time eq 'total') {
            for my $dir ($dir1, $dir2) {
                printf "%s: %5.2f\n", $dir, $time{$dir};
            }
        }
    }

    request_result $dir1, $id;
    request_result $dir2, $id;

    my $a = fetch_result $dir1, $id;
    my $b = fetch_result $dir2, $id;

    my $header_printed = 0;

    for my $key (keys %{$a}) {
        my $aa = $a->{$key};
        my $bb = $b->{$key};

        if (!ref $aa or !ref $bb) {
            next;
        }

        if ($key eq 'ledger') {
            $aa = convert_ledger $aa;
            $bb = convert_ledger $bb;
            my $aj = join "\n", map { to_json($_) } @{$aa};
            my $bj = join "\n", map { to_json($_) } @{$bb};
            if ($aj ne $bj) {
                print "\nDiff in $id" if !$header_printed++;
                # print "Ledger diffs";
                print diff \$aj, \$bj;
            }
        } else {
            my $aj = to_json($aa, { pretty => 1, canonical => 1 });
            my $bj = to_json($bb, { pretty => 1, canonical => 1 });
            if ($aj ne $bj) {
                print "\nDiff in $id" if !$header_printed++;
                print diff \$aj, \$bj;
            }
        }
    }
    
    if ($header_printed) {
        $diffcount++;
    }
}
