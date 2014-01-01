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
        my $pid = open2(my $reader, my $writer, "perl $dir/listgames.pl $target");
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

    for (@{$json->{res}}) {
        if (defined $_->{seconds_since_update}) {
            $_->{seconds_since_update} = int $_->{seconds_since_update};
        }
    }

    $json;
}

my ($dir1, $dir2) = (shift, shift);

my $dbh = get_db_connection;

my @modes = ("user 0 0",
             "other-user 0 0",
             "user 1 0",
             "user 0 1");

my $players = $dbh->selectall_arrayref("select username from player",
                                       {});                                    

my @queries = ();
for my $player (@{$players}) {
    $player = $player->[0];
    for my $mode (@modes) {
        push @queries, "$player $mode";
    }
}

my $count = 0;
for (@queries) {
    my $id = $_;
    ++$count;

    {
        local $| = 1; 
        printf "."; 
    }

    if ($count % 75 == 0) {
        print "\n";
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
}
