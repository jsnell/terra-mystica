#!/usr/bin/perl -w

use JSON;

my $tag = '?cache_tag=%%GIT_VERSION%%';

print "Content-type: text/javascript\r\n";
print "Cache-Control: no-cache\r\n";
print "Access-Control-Allow-Origin: *\r\n";

print "\r\n";

sub print_json {
    my $data = shift;
    my $out = encode_json $data;

    print $out;
}

print_json {
    js => {
        "/stc/prototype-1.7.1.js$tag",
        "/stc/faction.js$tag",
        "/stc/game.js$tag",
        "/stc/debug.js$tag",
    },
    css => {
        "/stc/style.js$tag",
    }
};

