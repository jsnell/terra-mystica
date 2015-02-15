use strict;

package Util::PasswordQuality;
use Exporter::Easy (EXPORT => [ 'password_too_weak' ]);

use Data::Password::Common qw(found);

sub password_too_weak {
    my ($username, $password) = @_;

    if (lc $password eq lc $username or
        (length $username >= 5 and
         ($password =~ /^\Q$username\E/i or
          $password =~ /\Q$username\E$/i))) {
        return "password is too similar to username\n";
    }

    if (found $password or
        lc $password eq 'terra' or
        lc $password eq 'terramystica' or
        lc $password eq 'snellman') {
        return "password is too common\n";
    }

    if (length $password < 6) {
        return "password is too short (must be at least 6 characters)\n";
    }

    return 0;
}


1;
