#!/usr/bin/perl -w

package DB::UserInfo;
use Exporter::Easy (
    EXPORT => [qw(fetch_user_stats)]
    );

use strict;

sub fetch_user_stats {
    my ($dbh, $username) = @_;

    my ($rows) =
        $dbh->selectall_arrayref("select faction, max(vp) as max_vp, sum(vp)/count(*) as mean_vp, count(*), count(case when rank = 1 then true end) as wins, count(case when rank = 1 then true end)*100/count(*) as win_percentage, array_agg(rank) as ranks from game_role where email in (select address from email where player=?) and faction != 'admin' and game in (select id from game where finished and not aborted and not exclude_from_stats) group by faction order by win_percentage desc",
                                 { Slice => {} },
                                 $username);
    $rows;
}

1;
