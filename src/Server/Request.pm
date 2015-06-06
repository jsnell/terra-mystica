use strict;
no indirect;

package Server::Request;

use parent qw(CGI::PSGI);

use Encode;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self;
}

sub param {
    my ($q, @args) = @_;
    if (wantarray) {
        map { decode('utf-8', $_) } $q->SUPER::multi_param(@args);
    } else {
        decode('utf-8', scalar $q->SUPER::param(@args));
    }
}

sub param_or_die {
    my ($q, $param) = @_;
    $q->param($param) // die "Required parameter '$param' undefined\n";
};

1;


