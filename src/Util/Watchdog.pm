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

        die "Request timed out\n";
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
