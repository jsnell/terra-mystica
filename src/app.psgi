#!/usr/bin/perl
# -*- mode: perl -*-

BEGIN {
    use File::Basename;
    push @INC, dirname $0;
}

use JSON;

use Server::Router;

\&Server::Router::psgi_router;
