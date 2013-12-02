use strict;

sub check_email_is_registered {
    my ($dbh, $address) = @_;

    my ($username) =
        $dbh->selectrow_array("select player from email where address=lower(?) and validated=true",
                              {},
                              $address);

    if (!defined $username) {
        die "Sorry. Adding unregistered or unvalidated email addresses to games is no longer supported. Please ask your players to register on the site, or to add an alias for their new email address on the settings page.\n";
    }

    $username;
}

sub check_username_is_registered {
    my ($dbh, $username) = @_;

    # XXX: primary address support
    my ($address, $actual_username) =
        $dbh->selectrow_array("select address, player from email where lower(player)=lower(?) and is_primary=true",
                              {},
                              $username);

    if (!defined $address) {
        die "There is no account with the username '$username'.\n";
    }

    ($actual_username, $address);
}

1;
