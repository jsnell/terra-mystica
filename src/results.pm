use strict;

use DBI;
use Digest::SHA1 qw(sha1_hex);
use File::Slurp qw(read_file);

sub get_finished_game_results {
    my $dbh = DBI->connect("dbi:Pg:dbname=terra-mystica", '', '',
                           { AutoCommit => 0, RaiseError => 1});
    my $secret = shift;

    my %res = ( error => '', results => [] );

    my $rows = $dbh->selectall_arrayref(
        "select game, faction, vp, rank, start_order, email.player, email from game_role left join game on game=game.id left join email on email=email.address where faction != 'admin' and game.finished",
        {});

    if (!$rows) {
        $res{error} = "db error";
    } else {
        for (@{$rows}) {
            push @{$res{results}}, {
                game => $_->[0],
                faction => $_->[1],
                vp => $_->[2],
                rank => $_->[3],
                start_order => $_->[4],
                username => $_->[5],
                id_hash => ($_->[6] ? sha1_hex($_->[6] . $secret) : undef),
            }
        }
    }

    $dbh->disconnect();

    %res;
}

1;
