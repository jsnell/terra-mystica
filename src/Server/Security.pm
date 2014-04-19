package Server::Security;
use Exporter::Easy (EXPORT => [ 'ensure_user_may_view_game' ]);

sub ensure_user_may_view_game {
    my ($username, $players, $metadata) = @_;

    if (!$metadata->{base_map}) {
        return 0;
    }

    if (!$username) {
        die "This is a restricted game. You must log in to view it.\n";
    }

    my @in_player_list = grep { $_->{username} eq $username } @{$players};

    if (!@in_player_list and $username ne 'jsnell' and $username ne 'nan') {
        die "This is a restricted game. Only players can view it.\n";
    }

    1;
}

1;
