use strict;

package Util::ServerUtil;
use Exporter::Easy (EXPORT => [ 'log_with_request' ]);

use JSON;
use POSIX;

sub log_with_request {
    my ($q, $error) = @_;
    chomp $error;

    my $timestamp = asctime localtime;
    chomp $timestamp;

    my $ip = $q->remote_host();
    my $username = $q->cookie('session-username') // '<none>';
    my $params = eval {
        my @vars = grep { !/password/ } $q->param;
        my %params = map { ($_ => $q->param($_)) } @vars;
        encode_json \%params
    };

    my $path_info = $q->path_info();
    print STDERR "[$timestamp] ip=$ip path=$path_info username=$username\nparams=$params\nERROR: $error\n", '-'x60, "\n";
}

1;
