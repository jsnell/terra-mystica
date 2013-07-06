#!/usr/bin/perl -w

print "Status: 303\r\n";
print "Set-Cookie: csrf-token=; Path=/\r\n";
print "Set-Cookie: session-username=; Path=/;\r\n";
print "Set-Cookie: session-token=; Path=/; HttpOnly\r\n";
print "Location: /\r\n";
print "Cache-Control: no-cache\r\n";
print "\r\n";
