use strict;

package DB::Settings;
use Exporter::Easy (EXPORT => [ 'fetch_user_settings',
                                'save_user_settings']);

sub fetch_user_settings {
    my ($dbh, $username) = @_;
    
    my %res = ();

    my $player = $dbh->selectrow_hashref(
        "select username, displayname, email_notify_turn, email_notify_all_moves, email_notify_chat from player where username = ?",
        {},
        $username);
    $res{$_} = $player->{$_} for keys %{$player};

    my $rows = $dbh->selectall_hashref(
        "select address, validated, is_primary from email where player = ?",
        'address',
        { Slice => {} },
        $username);
    $res{email} = $rows;

    \%res;
}

sub save_user_settings {
    my ($dbh, $username, $q) = @_;

    my $displayname = $q->param('displayname');
    my $primary_email = $q->param('primary_email');

    if (length $displayname > 30) {
        die "Display Name too long";
    }

    $dbh->do("begin");

    $dbh->do("update player set displayname=?, email_notify_turn=?, email_notify_all_moves=?, email_notify_chat=? where username=?",
             {},
             $displayname,
             $q->param('email_notify_turn'),
             $q->param('email_notify_all_moves'),
             $q->param('email_notify_chat'),
             $username);

    if ($primary_email) {
        $dbh->do("update email set is_primary=false where player=?",
                 {},
                 $username);
        $dbh->do("update email set is_primary=true where player=? and address=lower(?)",
                 {},
                 $username,
                 $primary_email);
    }

    $dbh->do("commit");
}

1;
