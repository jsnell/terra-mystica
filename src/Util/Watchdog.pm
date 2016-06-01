package Util::Watchdog;
use Exporter::Easy (EXPORT => [ 'with_watchdog', 'feed_watchdog' ]);

use Devel::StackTrace;

sub with_watchdog {
    my $alarm_triggered = 0;
    my ($timeout, $fun) = @_;

    local $SIG{ALRM} = sub {
        $alarm_triggered = 1;
        my $trace = Devel::StackTrace->new;
        for my $frame ($trace->frames()) {
            print STDERR "  ", $frame->as_string(), "\n";
            last if $frame->subroutine() eq 'Util::Watchdog::with_watchdog';
        }

        print "Request timed out\n";
        # Treat a watchdog timeout as a fatal error, rather than an
        # catchable exception. DBD::Pg is not async signal safe, and
        # gets in a permanently corrupted state if we unwind in the
        # middle of a DB operation. That instance of the code will
        # then not work again, producing user-visible errors until the
        # service is manually restarted. So just quit now, and let
        # the server process restart.
        exit 1;
    };

    eval {
        alarm $timeout;
        $fun->();
    };
    my $err = $@;

    alarm 0;

    if ($err) {
        die $err;
    }
}

sub feed_watchdog {
    my ($timeout) = @_;
    
    die "Can't feed watchdog -- not inside with_watchdog\n" if !$SIG{ALRM};

    alarm $timeout;
}

1;
